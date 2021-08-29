(import spork/path)

(varfn journey-date
  []
  (let [{:year year
         :month month
         :month-day month-day} (os/date)]
    (string/format "%04d-%02d-%02d" year month month-day)))

(varfn journey-time
  []
  (let [{:hours hours
         :minutes minutes
         :seconds seconds} (os/date)]
    (string/format "%02d_%02d_%02d.janet" hours minutes seconds)))

(varfn save-journey
  [path]
  (let [journey-dir (string ".freja-journey-" path)
        day-dir (string journey-dir path/sep (journey-date))
        journey-path (string day-dir path/sep (journey-time))]
    (os/mkdir journey-dir)
    (os/mkdir day-dir)
    (with [f (file/open journey-path :w)]
      (with [org-f (file/open path :r)]
        (file/write f (file/read org-f :all))))))

(varfn swap-journey
  [path]
  (let [journey-path (string ".freja-journey-" path)]
    (if-not (os/stat journey-path)
      (print "there is no journey " journey-path " for " path)
      (do
        (def content (slurp path))
        (def journey-content (slurp journey-path))

        # trying to restore content if something gets messed up
        (with [f (file/open path :w)]
          (try (do
                 (file/write f journey-content)
                 (with [journey (file/open journey-path :w)]
                   (try
                     (file/write journey content)
                     ([err fib]
                       (file/write journey journey-content)))))
            ([err fib]
              (file/write f content))))))))

(save-journey "journey.janet")
#(overwrite-journey "journey.janet")
#(swap-journey "journey.janet")


(comment
  # next steps:
  # 0. when opening file, save-new-journey
  # 1. c-s -> overwrite-journey
  # 2. c-e -> "regular save"
  # 3. "revert" -> swap-journey and refresh gap buffer

  #
)
