/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

// https://html.spec.whatwg.org/multipage/#the-websocket-interface

enum BinaryType { "blob", "arraybuffer" };

[Exposed=(Window,Worker)]
interface WebSocket : EventTarget {
    [Throws] constructor(DOMString url, optional (DOMString or sequence<DOMString>) protocols);
    readonly attribute DOMString url;
    //ready state
    const unsigned short CONNECTING = 0;
    const unsigned short OPEN = 1;
    const unsigned short CLOSING = 2;
    const unsigned short CLOSED = 3;
    readonly attribute unsigned short readyState;
    readonly attribute unsigned long long bufferedAmount;

    //networking
    attribute EventHandler onopen;
    attribute EventHandler onerror;
    attribute EventHandler onclose;
    //readonly attribute DOMString extensions;
    readonly attribute DOMString protocol;
    [Throws] void close(optional [Clamp] unsigned short code, optional USVString reason);

    //messaging
    attribute EventHandler onmessage;
    attribute BinaryType binaryType;
    [Throws] void send(USVString data);
    [Throws] void send(Blob data);
    [Throws] void send(ArrayBuffer data);
    [Throws] void send(ArrayBufferView data);
};

interface MessageEvent : Event {
  constructor(DOMString type, optional MessageEventInit eventInitDict = {});

  readonly attribute any data;
  readonly attribute USVString origin;
  readonly attribute DOMString lastEventId;
  readonly attribute MessageEventSource? source;
  readonly attribute FrozenArray<MessagePort> ports;

  void initMessageEvent(DOMString type, optional boolean bubbles = false, optional boolean cancelable = false, optional any data = null, optional USVString origin = "", optional DOMString lastEventId = "", optional MessageEventSource? source = null, optional sequence<MessagePort> ports = []);
};

dictionary MessageEventInit : EventInit {
  any data = null;
  USVString origin = "";
  DOMString lastEventId = "";
  MessageEventSource? source = null;
  sequence<MessagePort> ports = [];
};

// typedef (WindowProxy or MessagePort or ServiceWorker) MessageEventSource;
typedef (MessagePort or ServiceWorker) MessageEventSource;

[Exposed=(Window,Worker,AudioWorklet), Transferable]
interface MessagePort : EventTarget {
  void postMessage(any message, sequence<object> transfer);
  void postMessage(any message, optional PostMessageOptions options = {});
  void start();
  void close();

  // event handlers
  attribute EventHandler onmessage;
  attribute EventHandler onmessageerror;
};

dictionary PostMessageOptions {
  sequence<object> transfer = [];
};

interface ServiceWorker : EventTarget {
  readonly attribute USVString scriptURL;
  readonly attribute ServiceWorkerState state;
  void postMessage(any message, sequence<object> transfer);
  void postMessage(any message, optional PostMessageOptions options = {});

  // event
  attribute EventHandler onstatechange;
};
ServiceWorker includes AbstractWorker;

enum ServiceWorkerState {
  "parsed",
  "installing",
  "installed",
  "activating",
  "activated",
  "redundant"
};

