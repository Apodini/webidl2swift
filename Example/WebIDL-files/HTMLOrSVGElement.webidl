
interface mixin HTMLOrSVGElement {
  [SameObject] readonly attribute DOMStringMap dataset;
  attribute DOMString nonce; // intentionally no [CEReactions]

  [CEReactions] attribute boolean autofocus;
  [CEReactions] attribute long tabIndex;
  void focus(optional FocusOptions options = {});
  void blur();
};

dictionary FocusOptions {
  boolean preventScroll = false;
};
