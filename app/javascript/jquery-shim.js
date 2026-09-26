// jQuery global shim for legacy UMD/CJS plugins (chosen-js, adminlte,
// bootstrap-datepicker) that expect a free `jQuery`/`$` global at load time.
//
// Wired via esbuild `--inject` (see package.json "build"): esbuild prepends
// an import of the matching export to every module referencing those
// globals, so the assignment below always runs BEFORE the plugins evaluate.
// A plain `window.jQuery = ...` line in application.js cannot do this
// because ESM imports are hoisted and evaluate first.
import jQuery from "jquery";

const $ = jQuery;
window.jQuery = window.$ = jQuery;

export { jQuery, $ };
export default jQuery;
