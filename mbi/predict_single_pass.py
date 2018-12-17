"""Imputes markers with mbi models."""
# import clize
import h5py
from keras.models import load_model
import numpy as np
import os
from scipy.io import savemat
from scipy import stats


def sigmoid(x, x_0, k):
    """Sigmoid function.

    For use in weighted averaging of marker predictions from
    the forward and reverse passes.
    :param x: domain
    :param x_0: midpoint
    :parak k: exponent constant.
    """
    return 1 / (1 + np.exp(-k*(x-x_0)))


def predict_markers(model, X, bad_frames, markers_to_fix=None,
                    error_diff_thresh=.25, outlier_thresh=3,
                    return_member_data=False):
    """Imputes the position of missing markers.

    :param model: model to use for prediction
    :param X: marker data (n_frames x n_markers)
    :param bad_frames: loical matrix of shape == X.shape where 0 denotes a
                       tracked frame and 1 denotes a dropped frame
    :param fix_errors: boolean vector of length n_markers. True if you wish to
                       override marker on frames further than error_diff_thresh
                       from the previous prediction.
    :param error_diff_thresh: z-scored distance at which predictions override
                              marker measurements.
    :param outlier_thresh: Threshold at which to ignore model predictions.
    :param return_member_data: If true, also return the predictions of each
                               ensemble member in a matrix of size
                               n_members x n_frames x n_markers. The
    :return: preds, bad_frames
    """
    # Get the input lengths and find the first instance of all good frames.
    input_length = model.input.shape.as_list()[1]
    bad_frames = np.repeat(bad_frames, 3, axis=1) > .5
    startpoint = 0

    # See whether you should fix errors
    fix_errors = np.any(markers_to_fix)

    # Reshape and get the starting seed.
    X = X[None, ...]
    X_start = X[:, startpoint:(startpoint+input_length), :]

    # Preallocate
    preds = np.zeros((X.shape))
    preds[:, startpoint:(startpoint+input_length), :] = X_start
    pred = np.zeros((1, 1, X.shape[2]))

    if return_member_data:
        n_members = model.output_shape[1][1]
        member_stds = np.zeros((1, X.shape[1], X.shape[2]))
        member_pred = np.zeros((1, n_members, X.shape[2]))

        # At each step, generate a prediction, replace the predictions of
        # markers you do not want to predict with the ground truth, and append
        # the resulting vector to the end of the next input chunk.
        for i in range(startpoint, X.shape[1]-input_length-startpoint):
            if np.mod(i, 10000) == 0:
                print('Predicting frame: ', i, flush=True)
            next_frame_id = (startpoint+input_length)+i

            # If there is a marker prediction that is greater than the
            # difference threshold above, mark it as a bad frame.
            # These are likely just jumps or identity swaps from MoCap that
            # were not picked up by preprocessing.
            if fix_errors:
                diff = pred[:, 0, :] - X[:, next_frame_id, :]
                errors = np.squeeze(np.abs(diff) > error_diff_thresh)
                errors[~markers_to_fix] = False
                bad_frames[next_frame_id, errors] = True
            if np.any(bad_frames[next_frame_id, :]):
                pred, member_pred = model.predict(X_start)

            # Detect anomalous predictions.
            outliers = np.squeeze(np.abs(pred) > outlier_thresh)
            pred[:, 0, outliers] = X[:, next_frame_id, outliers]

            # Only use the predictions for the bad markers. Take the
            # predictions and append to the end of X_start for future
            # prediction.
            pred[:, 0, ~bad_frames[next_frame_id, :]] = \
                X[:, next_frame_id, ~bad_frames[next_frame_id, :]]
            member_pred[:, :, ~bad_frames[next_frame_id, :]] = float('nan')
            member_std = np.nanstd(member_pred, axis=1)
            preds[:, next_frame_id, :] = np.squeeze(pred)
            member_stds[0, next_frame_id, :] = np.squeeze(member_std)
            X_start = np.concatenate((X_start[:, 1:, :], pred), axis=1)
        return np.squeeze(preds), bad_frames, member_stds
    else:
        # At each step, generate a prediction, replace the predictions of
        # markers you do not want to predict with the ground truth, and append
        # the resulting vector to the end of the next input chunk.
        for i in range(startpoint, X.shape[1]-input_length-startpoint):
            if np.mod(i, 10000) == 0:
                print('Predicting frame: ', i, flush=True)
            next_frame_id = (startpoint+input_length)+i

            # If there is a marker prediction that is greater than the
            # difference threshold above, mark it as a bad frame.
            # These are likely just jumps or identity swaps from MoCap that
            # were not picked up by preprocessing.
            if fix_errors:
                diff = pred[:, 0, :] - X[:, next_frame_id, :]
                errors = np.squeeze(np.abs(diff) > error_diff_thresh)
                errors[~markers_to_fix] = False
                bad_frames[next_frame_id, errors] = True
            if np.any(bad_frames[next_frame_id, :]):
                pred = model.predict(X_start)

            # Detect anomalous predictions.
            outliers = np.squeeze(np.abs(pred) > outlier_thresh)
            pred[:, 0, outliers] = X[:, next_frame_id, outliers]

            # Only use the predictions for the bad markers. Take the
            # predictions and append to the end of X_start for future
            # prediction.
            pred[:, 0, ~bad_frames[next_frame_id, :]] = \
                X[:, next_frame_id, ~bad_frames[next_frame_id, :]]
            preds[:, next_frame_id, :] = np.squeeze(pred)
            X_start = np.concatenate((X_start[:, 1:, :], pred), axis=1)
        return np.squeeze(preds), bad_frames


def predict_single_pass(model_path, data_path, pass_direction, *,
                        save_path=None, stride=1, n_folds=10, fold_id=None,
                        markers_to_fix=None, error_diff_thresh=.25,
                        model=None):
    """Imputes the position of missing markers.

    :param model_path: Path to model to use for prediction.
    :param data_path: Path to marker and bad_frames data. Can be hdf5 or
                      mat -v7.3.
    :param pass_direction: Direction in which to impute markers.
                           Can be 'forward' or 'reverse'
    :param save_path: Path to a folder in which to store the prediction chunks.
    :param stride: stride length between frames for faster imputation.
    :param n_folds: Number of folds across which to divide data for faster
                    imputation.
    :param fold_id: Fold identity for this specific session.
    :param markers_to_fix: Markers for which to override suspicious MoCap
                           measurements
    :param error_diff_thresh: Z-scored difference threshold marking suspicious
                              frames
    :param model: Model to be used in prediction. Overrides model_path.
    :return: preds
    """
    if not (pass_direction == 'forward') | (pass_direction == 'reverse'):
        raise ValueError('pass_direction must be forward or reverse')

    # Check data extensions
    filename, file_extension = os.path.splitext(data_path)
    accepted_extensions = {'.h5', '.hdf5', '.mat'}
    if file_extension not in accepted_extensions:
        raise ValueError('Improper extension: hdf5 or \
                         mat -v7.3 file required.')

    # Load data
    print('Loading data')
    f = h5py.File(data_path, 'r')
    if file_extension in {'.h5', '.hdf5'}:
        markers = np.array(f['markers'][:]).T
        marker_means = np.array(f['marker_means'][:]).T
        marker_stds = np.array(f['marker_stds'][:]).T
        bad_frames = np.array(f['bad_frames'][:]).T
    else:
        # Get the markers data from the struct
        dset = 'markers_aligned_preproc'
        marker_names = list(f[dset].keys())
        n_frames_tot = f[dset][marker_names[0]][:].T.shape[0]
        n_dims = f[dset][marker_names[0]][:].T.shape[1]

        markers = np.zeros((n_frames_tot, len(marker_names)*n_dims))
        for i in range(len(marker_names)):
            marker = f[dset][marker_names[i]][:].T
            for j in range(n_dims):
                markers[:, i*n_dims + j] = marker[:, j]

        # Z-score the marker data
        marker_means = np.mean(markers, axis=0)
        marker_means = marker_means[None, ...]
        marker_stds = np.std(markers, axis=0)
        marker_stds = marker_stds[None, ...]
        print(marker_means)
        print(marker_stds)
        markers = stats.zscore(markers)

        # Get the bad_frames data from the cell
        dset = 'bad_frames_agg'
        n_markers = f[dset][:].shape[0]
        bad_frames = np.zeros((markers.shape[0], n_markers))
        for i in range(n_markers):
            reference = f[dset][i][0]
            bad_frames[np.squeeze(f[reference][:]).astype('int32') - 1, i] = 1

    # Get the start frame and number of frames after splitting the data up
    markers = markers[::stride, :]
    bad_frames = bad_frames[::stride, :]
    n_frames = int(np.floor(markers.shape[0]/n_folds))
    fold_id = int(fold_id)
    start_frame = n_frames * int(fold_id)

    # Also predict the remainder if on the last fold.
    if fold_id == (n_folds-1):
        markers = markers[start_frame:, :]
        bad_frames = bad_frames[start_frame:, :]
    else:
        markers = markers[start_frame:(start_frame + n_frames), :]
        bad_frames = bad_frames[start_frame:(start_frame + n_frames), :]

    # Load model
    if model is None:
        print('Loading model')
        model = load_model(model_path)

    # Check how many outputs the model has to handle it appropriately
    n_outputs = len(model.output_shape)
    if n_outputs == 2:
        return_member_data = True
    else:
        return_member_data = False
        member_stds = [None]

    # Set Markers to fix
    if markers_to_fix is None:
        markers_to_fix = np.zeros((markers.shape[1])) > 1
        # TODO(Skeleton): Automate this by including the skeleton.
        # Fix all arms, elbows, shoulders, shins, hips and legs.
        markers_to_fix[30:] = True
        # markers_to_fix[30:36] = True
        # markers_to_fix[42:] = True

    if pass_direction == 'reverse':
        markers = markers[::-1, :]
        bad_frames = bad_frames[::-1, :]

    print('Predicting %d frames starting at frame %d.'
          % (markers.shape[0], start_frame))

    # If the model can return the member predictions, do so.
    if return_member_data:
        print('Imputing markers: %s pass' % (pass_direction), flush=True)
        preds, bad_frames, member_stds = \
            predict_markers(model, markers, bad_frames,
                            markers_to_fix=markers_to_fix,
                            error_diff_thresh=error_diff_thresh,
                            return_member_data=return_member_data)
    else:
        # Forward predict
        print('Imputing markers: %s pass' % (pass_direction), flush=True)
        preds, bad_frames = \
            predict_markers(model, markers, bad_frames,
                            markers_to_fix=markers_to_fix,
                            error_diff_thresh=error_diff_thresh,
                            return_member_data=return_member_data)

    # Flip the data for the reverse cases to save in the correct direction.
    if pass_direction == 'reverse':
        markers = markers[::-1, :]
        preds = preds[::-1, :]
        bad_frames = bad_frames[::-1, :]
        member_stds = member_stds[:, ::-1, :]

    # Save predictions to a matlab file.
    if save_path is not None:
        file_name = '%s_fold_id_%d.mat' % (pass_direction, fold_id)
        if not os.path.exists(save_path):
            os.makedirs(save_path)
        save_path = os.path.join(save_path, file_name)
        print('Saving to %s' % (save_path))
        savemat(save_path, {'preds': preds, 'markers': markers,
                            'bad_frames': bad_frames,
                            'member_stds': np.squeeze(member_stds),
                            'n_folds': n_folds,
                            'fold_id': fold_id,
                            'pass_direction': pass_direction,
                            'marker_means': marker_means,
                            'marker_stds': marker_stds})

    return preds

if __name__ == "__main__":
    # Wrapper for running from commandline
    clize.run(predict_single_pass)
