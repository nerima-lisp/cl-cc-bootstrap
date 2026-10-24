((:feature "symbols"
  :source-dirs ("src/symbols")
  :test-dir "t/symbols"
  :facade-packages ("cl-cc/bootstrap")
  :domain-package "cl-cc/bootstrap/symbols"
  :infra-package nil
  :depends-on ())
 (:feature "backend-protocol"
  :source-dirs ("src/backend-protocol")
  :test-dir "t/backend-protocol"
  :facade-packages ("cl-cc/bootstrap" "cl-cc/backend-protocol")
  :domain-package "cl-cc/bootstrap/backend-protocol"
  :infra-package nil
  :depends-on ("symbols")))
