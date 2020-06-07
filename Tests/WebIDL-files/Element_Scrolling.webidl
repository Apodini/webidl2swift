enum ScrollLogicalPosition { "start", "center", "end", "nearest" };
dictionary ScrollIntoViewOptions : ScrollOptions {
  ScrollLogicalPosition block = "start";
  ScrollLogicalPosition inline = "nearest";
};

partial interface Element {
  DOMRectList getClientRects();
  [NewObject] DOMRect getBoundingClientRect();
  void scrollIntoView(optional (boolean or ScrollIntoViewOptions) arg = {});
  void scroll(optional ScrollToOptions options = {});
  void scroll(unrestricted double x, unrestricted double y);
  void scrollTo(optional ScrollToOptions options = {});
  void scrollTo(unrestricted double x, unrestricted double y);
  void scrollBy(optional ScrollToOptions options = {});
  void scrollBy(unrestricted double x, unrestricted double y);
  attribute unrestricted double scrollTop;
  attribute unrestricted double scrollLeft;
  readonly attribute long scrollWidth;
  readonly attribute long scrollHeight;
  readonly attribute long clientTop;
  readonly attribute long clientLeft;
  readonly attribute long clientWidth;
  readonly attribute long clientHeight;
};

[Exposed=(Window,Worker),
 Serializable]
interface DOMRectReadOnly {
    constructor(optional unrestricted double x = 0, optional unrestricted double y = 0,
            optional unrestricted double width = 0, optional unrestricted double height = 0);

    [NewObject] static DOMRectReadOnly fromRect(optional DOMRectInit other = {});

    readonly attribute unrestricted double x;
    readonly attribute unrestricted double y;
    readonly attribute unrestricted double width;
    readonly attribute unrestricted double height;
    readonly attribute unrestricted double top;
    readonly attribute unrestricted double right;
    readonly attribute unrestricted double bottom;
    readonly attribute unrestricted double left;

    [Default] object toJSON();
};

[Exposed=(Window,Worker),
 Serializable,
 LegacyWindowAlias=SVGRect]
interface DOMRect : DOMRectReadOnly {
    constructor(optional unrestricted double x = 0, optional unrestricted double y = 0,
            optional unrestricted double width = 0, optional unrestricted double height = 0);

    [NewObject] static DOMRect fromRect(optional DOMRectInit other = {});

    inherit attribute unrestricted double x;
    inherit attribute unrestricted double y;
    inherit attribute unrestricted double width;
    inherit attribute unrestricted double height;
};

dictionary DOMRectInit {
    unrestricted double x = 0;
    unrestricted double y = 0;
    unrestricted double width = 0;
    unrestricted double height = 0;
};

enum ScrollBehavior { "auto", "smooth" };

dictionary ScrollOptions {
    ScrollBehavior behavior = "auto";
};
dictionary ScrollToOptions : ScrollOptions {
    unrestricted double left;
    unrestricted double top;
};

partial interface Window {
    [NewObject] MediaQueryList matchMedia(CSSOMString query);
    [SameObject, Replaceable] readonly attribute Screen screen;

    // browsing context
    void moveTo(long x, long y);
    void moveBy(long x, long y);
    void resizeTo(long width, long height);
    void resizeBy(long x, long y);

    // viewport
    [Replaceable] readonly attribute long innerWidth;
    [Replaceable] readonly attribute long innerHeight;

    // viewport scrolling
    [Replaceable] readonly attribute double scrollX;
    [Replaceable] readonly attribute double pageXOffset;
    [Replaceable] readonly attribute double scrollY;
    [Replaceable] readonly attribute double pageYOffset;
    void scroll(optional ScrollToOptions options = {});
    void scroll(unrestricted double x, unrestricted double y);
    void scrollTo(optional ScrollToOptions options = {});
    void scrollTo(unrestricted double x, unrestricted double y);
    void scrollBy(optional ScrollToOptions options = {});
    void scrollBy(unrestricted double x, unrestricted double y);

    // client
    [Replaceable] readonly attribute long screenX;
    [Replaceable] readonly attribute long screenLeft;
    [Replaceable] readonly attribute long screenY;
    [Replaceable] readonly attribute long screenTop;
    [Replaceable] readonly attribute long outerWidth;
    [Replaceable] readonly attribute long outerHeight;
    [Replaceable] readonly attribute double devicePixelRatio;
};

[Exposed=Window]
interface DOMRectList {
    readonly attribute unsigned long length;
    getter DOMRect? item(unsigned long index);
};

interface MediaQueryList : EventTarget {
  readonly attribute CSSOMString media;
  readonly attribute boolean matches;
  void addListener(EventListener? callback);
  void removeListener(EventListener? callback);
           attribute EventHandler onchange;
};

typedef DOMString CSSOMString;

[Exposed=Window]
interface Screen {
  readonly attribute long availWidth;
  readonly attribute long availHeight;
  readonly attribute long width;
  readonly attribute long height;
  readonly attribute unsigned long colorDepth;
  readonly attribute unsigned long pixelDepth;
};