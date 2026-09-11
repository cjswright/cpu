;;; Directory Local Variables.  For more information evaluate:
;;;
;;;     M-x describe-variable RET dir-locals-class-alist RET

((verilog-mode
  . ((lsp-clients-svlangserver-includeIndexing . ["src/**/*.{sv,svh}"])
     (lsp-clients-svlangserver-launchConfiguration . "verilator -sv --lint-only -Wall --timing"))))
