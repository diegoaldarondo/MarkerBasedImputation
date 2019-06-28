"""Analyze the performance of an mbi model."""
import clize
import datetime
from keras.models import load_model
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import os
from scipy.io import loadmat, savemat
from utils import load_dataset, get_ids


def plot_history(history, save_path):
    """Plot the history of a model training.

    :param history: Model history
    :param save_path: Figure save path
    """
    p = plt.figure(figsize=(12, 8))
    plt.plot(history['loss'])
    plt.plot(history['val_loss'])
    plt.xlabel('Epoch', fontsize=18)
    plt.ylabel('Mean squared error Loss', fontsize=18)
    plt.legend(['Train', 'Valid'])
    plt.savefig(save_path, bbox_inches='tight')
    plt.close(p)


def predict_markers(model, X, markers_to_predict, num_frames=True,
                    outlier_thresh=3, return_member_data=False):
    """Predicts the position of particular markers.

    :param model: model to use for prediction
    :param X: data struct covering
    :param markers_to_predict: logical vector of shape (X.shape[2],) that is
                               True for markers that you would like to predict
                               and false otherwise
    :param num_frames: number of frames into future you would like to predict.
                       Cannot be > X.shape[1] default is the difference between
                       X.shape[1] and the model input shape.
    """
    if num_frames:
        num_frames = X.shape[1] - model.input.shape.as_list()[1]

    # Exceptions
    if num_frames > X.shape[1]:
        raise ValueError("Improper num_frames to predict: likely asked to " +
                         "predict a greater number of frames than were " +
                         "available.")
    if num_frames < 0:
        raise ValueError("Improper num_frames to predict: likely too few " +
                         "input frames.")
    if num_frames == 0:
        raise ValueError("Improper num_frames to predict: likely asked to" +
                         "predict zero frames.")

    # Get the input lengths and preallocate
    input_length = model.input.shape.as_list()[1]
    X_start = X[:, :input_length, :]
    count = 0
    preds = np.zeros((X.shape[0], num_frames, X.shape[2]))

    if return_member_data:
        # n_members = model.output_shape[1][1]
        # member_preds = \
        #     np.zeros((X.shape[0], n_members, num_frames, X.shape[2]))
        member_stds = \
            np.zeros((X.shape[0], num_frames, X.shape[2]))
        # At each step, generate a prediction, replace the predictions of
        # markers you do not want to predict with the ground truth, and
        # append the resulting vector to the end of the next input chunk.
        for i in range(num_frames):
            pred, member_pred = model.predict(X_start)
            pred[:, 0, ~markers_to_predict] = \
                X[:, input_length + count, ~markers_to_predict]
            preds[:, i, :] = np.squeeze(pred)
            # member_preds[:, :, i, :] = member_pred

            member_std = np.nanstd(member_pred, axis=1)
            member_stds[:, i, :] = member_std
            X_start = np.concatenate((X_start[:, 1:, :], pred), axis=1)
            count += 1
        return preds, member_stds
    else:
        # At each step, generate a prediction, replace the predictions of
        # markers you do not want to predict with the ground truth, and
        # append the resulting vector to the end of the next input chunk.
        for i in range(num_frames):
            pred = model.predict(X_start)
            pred[:, 0, ~markers_to_predict] = \
                X[:, input_length + count, ~markers_to_predict]
            preds[:, i, :] = np.squeeze(pred)
            X_start = np.concatenate((X_start[:, 1:, :], pred), axis=1)
            count += 1
        return preds


def sigmoid(x, x_0, k):
    """Sigmoid function.

    For use in weighted averaging of marker predictions from
    the forward and reverse passes.
    :param x: domain
    :param x_0: midpoint
    :parak k: exponent constant.
    """
    return 1 / (1 + np.exp(-k * (x - x_0)))


def plot_error_distribution_over_time(delta, delta_marker,
                                      marker_id, viz_directory,
                                      num_ktiles=5, maxbound=90):
    """Plot error k-tiles over time.

    :param delta: Absolute prediction errors
    :param delta_marker: Absolute prediction error for marker_id
    :param marker_id: Marker ID Number
    :param viz_directory: Directory in which to save images.
    :param num_ktiles: Number of k-tiles (5 = quantiles, etc.) Default 5.
    :param maxbound: Maximum percentiile to plot. Default 90.
    """
    f = plt.figure(figsize=(12, 8))
    t = range(delta.shape[1])

    # Color each of the k-tiles a different color
    c = plt.cm.viridis(np.linspace(0, 1, num_ktiles))

    for i in range(num_ktiles):
        # Find the upper bound of the k-tile
        pct = (i + 1) / num_ktiles * 100
        top = np.percentile(delta_marker, pct, axis=0)
        if i == (num_ktiles - 1):
            top = np.percentile(delta_marker, maxbound, axis=0)

        # Find the lower bound of the k-tile
        pct2 = i / num_ktiles * 100
        bot = np.percentile(delta_marker, pct2, axis=0)

        # Draw the k-tile
        plt.fill_between(t, top, bot, facecolor=c[i, :], alpha=1)

    # Plot the median
    plt.plot(t, np.median(delta_marker, axis=0), color='w', linewidth=3)
    plt.grid(axis='y')
    plt.ylabel('Median error (mm)', fontsize=18)
    plt.xlabel('Number of frames', fontsize=18)
    title = 'Marker %d 3d' % (marker_id)
    plt.title(title)
    s = 'multi_predict_error_distribution_vs_time_marker3d%d.png' % (marker_id)
    plt.savefig(os.path.join(viz_directory, s), bbox_inches='tight')
    plt.close(f)


def analyze_marker_predictions(model, total, totalR, Y, marker_means,
                               marker_stds, viz_directory,
                               plot_distribution=False):
    """Analyzes the performance of an mbi model on ground truth data.

    :param model: model to use for predictions
    :param total: Marker data over time interval you wish to predict, including
                  the input frames
    :param totalR: Marker data over the inverse of the time interval you wish
                  to predict, including the input frames
    :param Y: Target marker data
    :param marker_means: Mean position in real-world-coordinates (RWC) of all
                         markers.
    :param marker_stds: Standard deviation in RWC of all markers
    :param viz_directory: Directory in which to save images.
    """
    n_markers = total.shape[2]
    delta_markers = np.zeros((Y.shape[0], Y.shape[1], np.int32(n_markers / 3)))
    total_member_stds = np.zeros((Y.shape[0], Y.shape[1], n_markers))
    predictions = np.zeros((Y.shape[0], Y.shape[1], n_markers))

    # Check how many outputs the model has, and how many members if returning
    # member data.
    n_outputs = len(model.output_shape)
    if n_outputs == 2:
        return_member_data = True
    else:
        return_member_data = False
        # member_predsF = [None]
        # member_predsR = [None]
        member_stdsF = [None]
        member_stdsR = [None]

    # For each marker, predict position over all gaps and make plots.
    for marker_id in range(np.int32(n_markers / 3)):
        # Pick the markers you would like to predict
        predict_ids = marker_id * 3 + np.array([0, 1, 2])
        markers_to_predict = np.zeros((n_markers)) > 1
        markers_to_predict[predict_ids] = True

        # Predict markers
        print('Predicting marker ', (marker_id))
        start = datetime.datetime.now()
        if return_member_data:
            # Multi predict forward
            preds, member_stdsF = \
                predict_markers(model, total, markers_to_predict,
                                return_member_data=return_member_data)
            # Multi predict reverse
            predsR, member_stdsR = \
                predict_markers(model, totalR, markers_to_predict,
                                return_member_data=return_member_data)
            member_stdsR = member_stdsR[:, ::-1, :]
        else:
            # Multi predict forward
            preds = \
                predict_markers(model, total, markers_to_predict,
                                return_member_data=return_member_data)
            # Multi predict reverse
            predsR = \
                predict_markers(model, totalR, markers_to_predict,
                                return_member_data=return_member_data)
        elapsed = datetime.datetime.now() - start
        s = 'Finished predictions of marker %d in %f seconds' % \
            (marker_id, elapsed.total_seconds())
        print(s)

        # Convert to Real world coordinates
        Y_world = np.zeros((Y.shape))
        preds_world = np.zeros((preds.shape))
        predsR_world = np.zeros((predsR.shape))
        for i in range(Y_world.shape[2]):
            Y_world[:, :, i] = \
                Y[:, :, i] * marker_stds[0, i] + marker_means[0, i]
            preds_world[:, :, i] = \
                preds[:, :, i] * marker_stds[0, i] + marker_means[0, i]
            predsR_world[:, :, i] = \
                predsR[:, :, i] * marker_stds[0, i] + marker_means[0, i]

        predsR_world = predsR_world[:, ::-1, :]

        # Compute the weighted average
        # k = .2335 # value determined empirically by minimizing MSE
        k = 1
        weightR = sigmoid(np.arange(0, preds_world.shape[1]),
                          preds_world.shape[1] / 2, k)
        weight = 1 - weightR
        preds_world_weighted_average = np.zeros((preds_world.shape))
        member_stds = np.zeros((preds_world.shape))
        for i in range(preds_world.shape[0]):
            for j in range(preds_world.shape[2]):
                preds_world_weighted_average[i, :, j] = \
                    preds_world[i, :, j] * weight + predsR_world[i, :, j] * weightR
                member_stds[i, :, j] = \
                    np.sqrt(((member_stdsF[i, :, j]**2) * weight) +
                            ((member_stdsR[i, :, j]**2) * weightR))
        delta = np.abs(Y_world - preds_world_weighted_average)
        delta_marker = np.sqrt(np.sum(delta[:, :, predict_ids]**2, axis=2))

        # Plot the distribution
        if plot_distribution:
            plot_error_distribution_over_time(delta, delta_marker,
                                              marker_id, viz_directory)

        delta_markers[:, :, marker_id] = delta_marker
        total_member_stds[:, :, predict_ids] = member_stds[:, :, predict_ids]
        predictions[:, :, predict_ids] = \
            preds_world_weighted_average[:, :, predict_ids]

    return delta_markers, total_member_stds, predictions


def analyze_performance(model_base_path, data_path, *, run_name=None,
                        viz_directory=None, model_name='best_model.h5',
                        default_input_length=9, testing_set_only=False,
                        analyze_history=True, plot_distribution=True,
                        analyze_multi_prediction=True,
                        load_training_info=True, min_gap_length=10,
                        max_gap_length=100, stride=1, skip=500,
                        save_path=None
                        ):
    """Analyzes model performance using a variety of methods.

    :param model_base_path: Base path of model to be analyzed
    :param data_path: Dataset to analyze
    :param run_name: Name of the folder in which to keep the analysis data
    :param model_name: Name of model to use within model_base_path
    :param default_input_length: Input length is determined by
                                 training_info.mat in model_base_path.
                                 If this fails use default_input_length.
    :param testing_set_only: Use only samples from the model's testing set
    :param analyze_history: Make figure plotting training losses over time
    :param plot_distribution: Plots the error distribution as a function of
                              gap length
    :param analyze_multi_prediction: Perform multiple prediction with
                                     replacement analysis
    :param load_training_info: Use training_info from model training.
    :param min_gap_length: Length of the shortest gap to analyze during
                           multipredict
    :param max_gap_length: Length of the longeset gap to analyze during
                           multipredict
    :param stride: Temporal downsampling rate
    :param skip: When calculating the error distribution over time, only take
                 every skip-th example trace to save time.
    """
    if run_name is None:
        run_name = datetime.datetime.now().strftime('%y_%m_%d_%H_%M_%S_%f')
        print('Created run: %s' % (run_name))

    if viz_directory is None:
        viz_directory = \
            os.path.join(os.path.join(model_base_path, 'viz'), run_name)
        print('Created viz directory: %s' % (viz_directory))
    if not os.path.exists(viz_directory):
        os.makedirs(viz_directory)

    # Look for model data in the training_info, if possible.
    try:
        model_info = \
            loadmat(os.path.join(model_base_path, 'training_info.mat'))
        input_length = model_info['input_length'][:]
    except KeyError:
        input_length = default_input_length

    if analyze_history:
        print('Plotting history')
        history = loadmat(os.path.join(model_base_path, 'history.mat'))
        plot_history(history, os.path.join(model_base_path, 'history.png'))

    # Load the model
    print('Loading model')
    model = load_model(os.path.join(model_base_path, model_name))

    print('Loading data')
    markers, marker_means, marker_stds, bad_frames, moving_frames = \
        load_dataset(data_path)
    markers = markers[::stride, :]
    bad_frames = bad_frames[::stride, :]

    lengths = np.arange(min_gap_length, max_gap_length + 1, 10)

    # Set up variables to save to matlab cells.
    delta_markers = np.zeros((lengths.shape[0],), dtype=np.object)
    member_stds = np.zeros((lengths.shape[0],), dtype=np.object)
    predictions = np.zeros((lengths.shape[0],), dtype=np.object)
    X = np.zeros((lengths.shape[0],), dtype=np.object)
    Y = np.zeros((lengths.shape[0],), dtype=np.object)
    input_ids = np.zeros((lengths.shape[0],), dtype=np.object)
    target_ids = np.zeros((lengths.shape[0],), dtype=np.object)
    total = np.zeros((lengths.shape[0],), dtype=np.object)

    for i in range(lengths.shape[0]):
        # Get Ids
        print('Getting indices %d' % (i), flush=True)
        [input_ids[i], target_ids[i]] = get_ids(bad_frames, input_length,
                                                input_length + lengths[i],
                                                True, True)

        # Get the data corresponding to the indices
        print('Indexing into data')
        X[i] = markers[input_ids[i][::skip, :], :]
        Y[i] = markers[target_ids[i][::skip, :lengths[i]], :]
        XR = markers[target_ids[i][::skip, :(lengths[i] - 1):-1], :]
        YR = Y[i][:, ::-1, :]

        # Concatenate for use in the multiple prediction function
        total[i] = np.concatenate((X[i], Y[i]), axis=1)
        totalR = np.concatenate((XR, YR), axis=1)

        run_folder = 'length_%d' % (lengths[i])
        save_directory = os.path.join(viz_directory, run_folder)
        if not os.path.exists(save_directory):
            os.makedirs(save_directory)

        # Analyze marker predictions over time
        delta_markers[i], member_stds[i], predictions[i] = \
            analyze_marker_predictions(model, total[i], totalR, Y[i],
                                       marker_means, marker_stds,
                                       save_directory,
                                       plot_distribution=plot_distribution)

    print('Saving predictions')
    savemat(os.path.join(viz_directory, 'errors.mat'),
            {'delta_markers': delta_markers, 'member_stds': member_stds,
             'input': X, 'target': Y, 'input_ids': input_ids,
             'skip': skip, 'stride': stride, 'target_ids': target_ids,
             'markers': markers, 'total': total, 'marker_stds': marker_stds,
<<<<<<< HEAD
             'marker_means': marker_means, 'predictions': predictions})
=======
             'marker_means': marker_means})
>>>>>>> f3a986bb7c84eaa4badc22b96f1ee4a88df0b8d9


if __name__ == "__main__":
    # Wrapper for running from commandline
    clize.run(analyze_performance)
