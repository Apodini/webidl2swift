
[Exposed=(Window,Worker)]
interface Performance : EventTarget {
    DOMHighResTimeStamp now();
    readonly attribute DOMHighResTimeStamp timeOrigin;
    [Default] object toJSON();
};

partial interface mixin WindowOrWorkerGlobalScope {
  [Replaceable] readonly attribute Performance performance;
};
Window includes WindowOrWorkerGlobalScope;

partial interface Performance {
  PerformanceEntryList getEntries ();
  PerformanceEntryList getEntriesByType (DOMString type);
  PerformanceEntryList getEntriesByName (DOMString name, optional DOMString type);
};
typedef sequence<PerformanceEntry> PerformanceEntryList;

dictionary PerformanceMarkOptions {
    any detail;
    DOMHighResTimeStamp startTime;
};

dictionary PerformanceMeasureOptions {
    any detail;
    (DOMString or DOMHighResTimeStamp) start;
    DOMHighResTimeStamp duration;
    (DOMString or DOMHighResTimeStamp) end;
};

partial interface Performance {
    PerformanceMark mark(DOMString markName, optional PerformanceMarkOptions markOptions = {});
    undefined clearMarks(optional DOMString markName);
    PerformanceMeasure measure(DOMString measureName, optional (DOMString or PerformanceMeasureOptions) startOrMeasureOptions = {}, optional DOMString endMark);
    undefined clearMeasures(optional DOMString measureName);
};

[Exposed=(Window,Worker)]
interface PerformanceMeasure : PerformanceEntry {
  readonly attribute any detail;
};

[Exposed=(Window,Worker)]
interface PerformanceEntry {
  readonly    attribute DOMString           name;
  readonly    attribute DOMString           entryType;
  readonly    attribute DOMHighResTimeStamp startTime;
  readonly    attribute DOMHighResTimeStamp duration;
  [Default] object toJSON();
};

[Exposed=(Window,Worker)]
interface PerformanceMark : PerformanceEntry {
  constructor(DOMString markName, optional PerformanceMarkOptions markOptions = {});
  readonly attribute any detail;
};
