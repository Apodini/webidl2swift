[Exposed=Window]
interface MediaSource : EventTarget {
    constructor();
    readonly        attribute SourceBufferList    sourceBuffers;
    readonly        attribute SourceBufferList    activeSourceBuffers;
    readonly        attribute ReadyState          readyState;
                    attribute unrestricted double duration;
                    attribute EventHandler        onsourceopen;
                    attribute EventHandler        onsourceended;
                    attribute EventHandler        onsourceclose;
    SourceBuffer   addSourceBuffer (DOMString type);
    undefined           removeSourceBuffer (SourceBuffer sourceBuffer);
    undefined           endOfStream (optional EndOfStreamError error);
    undefined           setLiveSeekableRange (double start, double end);
    undefined           clearLiveSeekableRange ();
    static boolean isTypeSupported (DOMString type);
};

enum ReadyState {
    "closed",
    "open",
    "ended"
};

enum EndOfStreamError {
    "network",
    "decode"
};

[Exposed=Window]
interface SourceBufferList : EventTarget {
    readonly        attribute unsigned long length;
                    attribute EventHandler  onaddsourcebuffer;
                    attribute EventHandler  onremovesourcebuffer;
    getter SourceBuffer (unsigned long index);
};

[Exposed=Window]
interface SourceBuffer : EventTarget {
                    attribute AppendMode          mode;
    readonly        attribute boolean             updating;
    readonly        attribute TimeRanges          buffered;
                    attribute double              timestampOffset;
    readonly        attribute AudioTrackList      audioTracks;
    readonly        attribute VideoTrackList      videoTracks;
    readonly        attribute TextTrackList       textTracks;
                    attribute double              appendWindowStart;
                    attribute unrestricted double appendWindowEnd;
                    attribute EventHandler        onupdatestart;
                    attribute EventHandler        onupdate;
                    attribute EventHandler        onupdateend;
                    attribute EventHandler        onerror;
                    attribute EventHandler        onabort;
    undefined appendBuffer (BufferSource data);
    undefined abort ();
    undefined remove (double start, unrestricted double end);
};

[Exposed=Window]
interface AudioTrackList : EventTarget {
  readonly attribute unsigned long length;
  getter AudioTrack (unsigned long index);
  AudioTrack? getTrackById(DOMString id);

  attribute EventHandler onchange;
  attribute EventHandler onaddtrack;
  attribute EventHandler onremovetrack;
};

[Exposed=Window]
interface AudioTrack {
  readonly attribute DOMString id;
  readonly attribute DOMString kind;
  readonly attribute DOMString label;
  readonly attribute DOMString language;
  attribute boolean enabled;
};

[Exposed=Window]
interface VideoTrackList : EventTarget {
  readonly attribute unsigned long length;
  getter VideoTrack (unsigned long index);
  VideoTrack? getTrackById(DOMString id);
  readonly attribute long selectedIndex;

  attribute EventHandler onchange;
  attribute EventHandler onaddtrack;
  attribute EventHandler onremovetrack;
};

[Exposed=Window]
interface VideoTrack {
  readonly attribute DOMString id;
  readonly attribute DOMString kind;
  readonly attribute DOMString label;
  readonly attribute DOMString language;
  attribute boolean selected;
};

enum AppendMode {
    "segments",
    "sequence"
};

interface TimeRanges {
  readonly attribute unsigned long length;
  double start(unsigned long index);
  double end(unsigned long index);
};

interface TextTrackList : EventTarget {
  readonly attribute unsigned long length;
  getter TextTrack (unsigned long index);
  TextTrack? getTrackById(DOMString id);

  attribute EventHandler onchange;
  attribute EventHandler onaddtrack;
  attribute EventHandler onremovetrack;
};

enum TextTrackMode { "disabled",  "hidden",  "showing" };
enum TextTrackKind { "subtitles",  "captions",  "descriptions",  "chapters",  "metadata" };

[Exposed=Window]
interface TextTrack : EventTarget {
  readonly attribute TextTrackKind kind;
  readonly attribute DOMString label;
  readonly attribute DOMString language;

  readonly attribute DOMString id;
  readonly attribute DOMString inBandMetadataTrackDispatchType;

  attribute TextTrackMode mode;

  readonly attribute TextTrackCueList? cues;
  readonly attribute TextTrackCueList? activeCues;

  undefined addCue(TextTrackCue cue);
  undefined removeCue(TextTrackCue cue);

  attribute EventHandler oncuechange;
};

[Exposed=Window]
interface TextTrackCue : EventTarget {
  readonly attribute TextTrack? track;

  attribute DOMString id;
  attribute double startTime;
  attribute double endTime;
  attribute boolean pauseOnExit;

  attribute EventHandler onenter;
  attribute EventHandler onexit;
};

[Exposed=Window]
interface TextTrackCueList {
  readonly attribute unsigned long length;
  getter TextTrackCue (unsigned long index);
  TextTrackCue? getCueById(DOMString id);
};
