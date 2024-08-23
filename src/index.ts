import {NativeModules, Image, Dimensions} from 'react-native';
const {width, height} = Dimensions.get('window');

export enum MediaType {
  VIDEO = 'video',
  IMAGE = 'image',
  ALL = 'all',
}

export type Results = {
  path: string;
  fileName: string;
  localIdentifier: string;
  width: number;
  height: number;
  mime: string;
  size: number;
  bucketId?: number;
  realPath?: string;
  parentFolderName?: string;
  creationDate?: string;
  crop?: {
    width: number;
    height: number;
    path: string;
    size: number
  }
};

export interface VideoResults extends Results {
  type: MediaType.VIDEO;
  thumbnail?: string;
}

export interface ImageResults extends Results {
  type: MediaType.IMAGE;
  thumbnail?: undefined;
}

export type PickerErrorCode =
  | 'PICKER_CANCELLED'
  | 'NO_LIBRARY_PERMISSION'
  | 'NO_CAMERA_PERMISSION';

export type Options<T extends MediaType = MediaType.ALL> = {
  mediaType?: T;
  isPreview?: boolean;
  isExportThumbnail?: boolean;
  selectedColor?: string;
  tapHereToChange?: string;
  cancelTitle?: string;
  doneTitle?: string;
  emptyMessage?: string;
  emptyImage?: Image;
  selectMessage?: string;
  deselectMessage?: string;
  usedCameraButton?: boolean;
  usedPrefetch?: boolean;
  previewAtForceTouch?: boolean;
  allowedLivePhotos?: boolean;
  allowedVideo?: boolean;
  allowedAlbumCloudShared?: boolean;
  allowedPhotograph?: boolean; // for camera ?: allow this option when you want to take a photos
  allowedVideoRecording?: boolean; //for camera ?: allow this option when you want to recording video.
  maxVideoDuration?: Number; //for camera ?: max video recording duration
  autoPlay?: boolean;
  muteAudio?: boolean;
  preventAutomaticLimitedAccessAlert?: boolean; // newest iOS 14
  numberOfColumn?: number;
  maxSelectedAssets?: number;
  fetchOption?: Object;
  fetchCollectionOption?: Object;
  maximumMessageTitle?: string;
  maximumMessage?: string;
  messageTitleButton?: string;
  //resize thumbnail
  thumbnailWidth?: number;
  thumbnailHeight?: number;
  haveThumbnail?: boolean;
  //crop
  cropWidth?: number;
  cropHeight?: number;
};

export interface SinglePickerOptions {
  selectedAssets?: Results;
  singleSelectedMode: true;
}

export interface MultiPickerOptions {
  selectedAssets?: Results[];
  singleSelectedMode?: false;
}

// interface MediaTypeOptions {
//   [MediaType.VIDEO]: {isExportThumbnail?: boolean};
//   [MediaType.ALL]: MediaTypeOptions[MediaType.VIDEO];
// }

interface MediaTypeResults {
  [MediaType.IMAGE]: ImageResults;
  [MediaType.VIDEO]: VideoResults;
  [MediaType.ALL]: ImageResults | VideoResults;
}

export type IOpenPicker = <T extends MediaType = MediaType.ALL>(
  options: Options
) => Promise<MediaTypeResults[T] | MediaTypeResults[T][]>;

let defaultOptions = {
  //**iOS**//
  usedPrefetch: false,
  allowedAlbumCloudShared: false,
  muteAudio: true,
  autoPlay: true,
  //resize thumbnail
  haveThumbnail: true,

  thumbnailWidth: Math.round(width / 2),
  thumbnailHeight: Math.round(height / 2),
  allowedLivePhotos: true,
  preventAutomaticLimitedAccessAlert: true, // newest iOS 14
  emptyMessage: 'No albums',
  selectMessage: 'Select',
  deselectMessage: 'Deselect',
  selectedColor: '#FB9300',
  maximumMessageTitle: 'Notification',
  maximumMessage: 'You have selected the maximum number of media allowed',
  maximumVideoMessage: 'You have selected the maximum number of video allowed',
  messageTitleButton: 'OK',
  cancelTitle: 'Cancel',
  tapHereToChange: 'Tap here to change',

  //****//

  //**Android**//

  //****//

  //**Both**//
  usedCameraButton: true,
  allowedVideo: true,
  allowedPhotograph: true, // for camera : allow this option when you want to take a photos
  allowedVideoRecording: false, //for camera : allow this option when you want to recording video.
  maxVideoDuration: 60, //for camera : max video recording duration
  numberOfColumn: 3,
  maxSelectedAssets: 20,
  doneTitle: 'Done',
  isPreview: true,
  mediaType: 'all',
  isExportThumbnail: false,
  maxVideo: 20,
  selectedAssets: [],
  singleSelectedMode: false,
  isCrop: false,
  isCropCircle: false,
  cropWidth: 0,
  cropHeight: 0,
};

export const openPicker: IOpenPicker = (optionsPicker) => {
  const options = {
    ...defaultOptions,
    ...optionsPicker,
  };
  const isSingle = options?.singleSelectedMode ?? false;
  if (isSingle) options.selectedAssets = [];

  return new Promise(async (resolve, reject) => {
    try {
      const response = await NativeModules.MultipleImagePicker.openPicker(
        options
      );
      if (response?.length) {
        if (isSingle) {
          resolve(response[0]);
        }
        resolve(response);
        return;
      }
      resolve([]);
    } catch (e) {
      reject(e);
    }
  });
};

