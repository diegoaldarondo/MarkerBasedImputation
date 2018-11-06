"""Imputes markers with mbi models."""
import clize
import numpy as np
import h5py
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
    markers = None
    bad_framesF = None
    bad_framesR = None
    predsF = None
    predsR = None
    member_predsF = None
    member_predsR = None
    for i in range(n_folds_to_merge):
        print('%d' % (i), flush=True)
        data = loadmat(fold_paths[i])
        pass_direction = data['pass_direction'][:]
        markers_single_fold = np.array(data['markers'][:])
        preds_single_fold = np.array(data['preds'][:])
        member_preds_single_fold = np.array(data['member_preds'][:])
        bad_frames_single_fold = np.array(data['bad_frames'][:])

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

    marker_means = np.array(data['marker_means'][:])
    marker_stds = np.array(data['marker_stds'][:])
    data = None

    print(markers.shape)
    print(predsF.shape)
    print(bad_framesF.shape)
    print(member_predsF.shape)
    print(marker_means.shape)
    print(marker_stds.shape, flush=True)
    # Convert to real world coordinates
    # markers = np.zeros((markers.shape))
    # predsF = np.zeros((predsF.shape))
    # predsR = np.zeros((predsR.shape))
    for i in range(markers.shape[1]):
        markers[:, i] = \
            markers[:, i]*marker_stds[0, i] + marker_means[0, i]
        predsF[:, i] = \
            predsF[:, i]*marker_stds[0, i] + marker_means[0, i]
        predsR[:, i] = \
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
    print('Computing weighted average', flush=True)
    preds = np.zeros(predsF.shape)
    for i in range(bad_frames.shape[1]*3):
        print('marker number: %d' % (i), flush=True)
        is_bad = bad_frames[:, np.floor(i/3).astype('int32')]
        CC = measure.label(is_bad, background=0)
        num_CC = len(np.unique(CC))-1
        preds[:, i] = predsF[:, i]
        for j in range(num_CC):
            length_CC = np.sum(CC == (j+1))
            x_0 = np.round(length_CC/2)
            k = 1
            weightR = sigmoid(np.arange(length_CC), x_0, k)
            weightF = 1-weightR
            preds[CC == (j+1), i] = \
                (predsF[CC == (j+1), i]*weightF) +\
                (predsR[CC == (j+1), i]*weightR)

    # Save predictions to a matlab file.
    if save_path is not None:
        s = 'Saving to %s' % (save_path)
        print(s)
        with h5py.File(save_path, "w") as f:
            f.create_dataset("preds", preds)
            f.create_dataset("markers", markers)
            f.create_dataset("badFrames", bad_frames)
            f.create_dataset("member_predsF", member_predsF)
            f.create_dataset("member_predsR", member_predsR)
        # savemat(save_path, {'preds': preds, 'markers': markers,
        #                     'badFrames': bad_frames,
        #                     'member_predsF': member_predsF,
        #                     'member_predsR': member_predsR})

    return preds

if __name__ == "__main__":
    # Wrapper for running from commandline
    clize.run(merge)
