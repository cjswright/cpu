;;; Directory Local Variables.  For more information evaluate:
;;;
;;;     M-x describe-variable RET dir-locals-class-alist RET

((verilog-mode
  . ((verilog-ts-indent-level . 2)
     (lsp-clients-svlangserver-includeIndexing . ["**/*.{sv,svh}"])
     (lsp-clients-svlangserver-mustIncludeIndexing . ["**/*.{sv,svh}"])
     (lsp-clients-svlangserver-excludeIndexing . ["**/build/**/*.{sv,svh}"])
     (lsp-clients-svlangserver-launchConfiguration . "verilator -sv --lint-only -Wall --timing"))))
