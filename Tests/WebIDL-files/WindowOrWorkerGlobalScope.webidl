//typedef (DOMString or Function) TimerHandler;

interface mixin WindowOrWorkerGlobalScope {
  [Replaceable] readonly attribute USVString origin;

  // base64 utility methods
  // DOMString btoa(DOMString data);
  // ByteString atob(DOMString data);

  // timers
  // long setTimeout(TimerHandler handler, optional long timeout = 0, any... arguments);
  // undefined clearTimeout(optional long handle = 0);
  // long setInterval(TimerHandler handler, optional long timeout = 0, any... arguments);
  // undefined clearInterval(optional long handle = 0);

  // microtask queuing
  // undefined queueMicrotask(VoidFunction callback);

  // ImageBitmap
  // Promise<ImageBitmap> createImageBitmap(ImageBitmapSource image, optional ImageBitmapOptions options = {});
  // Promise<ImageBitmap> createImageBitmap(ImageBitmapSource image, long sx, long sy, long sw, long sh, optional ImageBitmapOptions options = {});
};
Window includes WindowOrWorkerGlobalScope;
WorkerGlobalScope includes WindowOrWorkerGlobalScope;
