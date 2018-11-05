"""Imputes markers with mbi models."""
import clize
import numpy as np
from scipy.io import savemat, loadmat
from skimage import measure


def sigmoid(x, x_0, k):
    """Sigmoid function.

    For use in weighted averaging of marker predictions from
    the forward and reverse passes.
    :param x: domain
    :param x_0: midpoint
    :parak k: exponent constant.
    """
    return 1 / (1 + np.exp(-k*(x-x_0)))


def merge(save_path, *fold_paths):
    """Merge the predictions from chunked passes.

    :param save_path: Path to .mat file where merged predictions will be saved.
    :param fold_paths: List of paths to chunked predictions to merge.
    """
    n_folds_to_merge = len(fold_paths)
    data = [None]*n_folds_to_merge
    markers = None
    bad_framesF = None
    bad_framesR = None
    predsF = None
    predsR = None
    member_predsF = None
    member_predsR = None
    for i in range(n_folds_to_merge):
        data[i] = loadmat(fold_paths[i])
        pass_direction = data[i]['pass_direction'][:]
        markers_single_fold = np.array(data[i]['markers'][:])
        preds_single_fold = np.array(data[i]['preds'][:])
        member_preds_single_fold = np.array(data[i]['member_preds'][:])
        bad_frames_single_fold = np.array(data[i]['bad_frames'][:])

        if (markers is None) & (pass_direction == 'forward'):
            markers = markers_single_fold
        elif (pass_direction == 'forward'):
            markers = np.concatenate((markers, markers_single_fold), axis=0)

        if (bad_framesF is None) & (pass_direction == 'forward'):
            bad_framesF = bad_frames_single_fold
        elif (pass_direction == 'forward'):
            bad_framesF = \
                np.concatenate((bad_framesF, bad_frames_single_fold), axis=0)

        if (bad_framesR is None) & (pass_direction == 'reverse'):
            bad_framesR = bad_frames_single_fold
        elif (pass_direction == 'reverse'):
            bad_framesR = \
                np.concatenate((bad_framesR,
                                bad_frames_single_fold), axis=0)

        if (predsF is None) & (pass_direction == 'forward'):
            predsF = preds_single_fold
        elif (pass_direction == 'forward'):
            predsF = np.concatenate((predsF, preds_single_fold), axis=0)

        if (predsR is None) & (pass_direction == 'reverse'):
            predsR = preds_single_fold
        elif (pass_direction == 'reverse'):
            predsR = \
                np.concatenate((predsR, preds_single_fold), axis=0)

        if (member_predsF is None) & (pass_direction == 'forward'):
            member_predsF = member_preds_single_fold
        elif (pass_direction == 'forward'):
            member_predsF = \
                np.concatenate((member_predsF,
                                member_preds_single_fold), axis=1)

        if (member_predsR is None) & (pass_direction == 'reverse'):
            member_predsR = member_preds_single_fold
        elif (pass_direction == 'reverse'):
            member_predsR = \
                np.concatenate((member_predsR,
                                member_preds_single_fold), axis=1)

    marker_means = np.array(data[0]['marker_means'][:])
    marker_stds = np.array(data[0]['marker_stds'][:])
    print(markers.shape)
    print(predsF.shape)
    print(bad_framesF.shape)
    print(member_predsF.shape)
    print(marker_means.shape)
    print(marker_stds.shape)
    # Convert to real world coordinates
    markers_world = np.zeros((markers.shape))
    predsF_world = np.zeros((predsF.shape))
    predsR_world = np.zeros((predsR.shape))
    for i in range(markers_world.shape[1]):
        markers_world[:, i] = \
            markers[:, i]*marker_stds[0, i] + marker_means[0, i]
        predsF_world[:, i] = \
            predsF[:, i]*marker_stds[0, i] + marker_means[0, i]
        predsR_world[:, i] = \
            predsR[:, i]*marker_stds[0, i] + marker_means[0, i]

    # This is not necessarily all of the error frames from
    # multiple_predict_recording_with_replacement, but if they overlap,
    # we would just take the weighted average.
    bad_frames = np.zeros((bad_framesF.shape[0],
                           np.round(bad_framesF.shape[1]/3).astype('int32')))
    for i in range(bad_frames.shape[1]):
        bad_frames[:, i] = np.any(bad_framesF[:, (i*3):(i*3)+3]
                                  & bad_framesR[:, (i*3):(i*3)+3], axis=1)

    # Compute the weighted average of the forward and reverse predictions using
    # a logistic function
    print('Computing weighted average')
    preds_world = np.zeros(predsF_world.shape)
    for i in range(bad_frames.shape[1]*3):
        is_bad = bad_frames[:, np.floor(i/3).astype('int32')]
        CC = measure.label(is_bad, background=0)
        num_CC = len(np.unique(CC))-1
        preds_world[:, i] = predsF_world[:, i]
        for j in range(num_CC):
            length_CC = np.sum(CC == (j+1))
            x_0 = np.round(length_CC/2)
            k = 1
            weightR = sigmoid(np.arange(length_CC), x_0, k)
            weightF = 1-weightR
            preds_world[CC == (j+1), i] = \
                (predsF_world[CC == (j+1), i]*weightF) +\
                (predsR_world[CC == (j+1), i]*weightR)

    # Save predictions to a matlab file.
    if save_path is not None:
        s = 'Saving to %s' % (save_path)
        print(s)
        savemat(save_path, {'preds': preds_world, 'markers': markers_world,
                            'badFrames': bad_frames,
                            'member_predsF': member_predsF,
                            'member_predsR': member_predsR})

    return preds_world

if __name__ == "__main__":
    # Wrapper for running from commandline
    clize.run(merge)
