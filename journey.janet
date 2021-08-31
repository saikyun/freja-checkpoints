# TODO: don't crash when there are no checkpoints

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
    (string/format "%02d_%02d_%02d" hours minutes seconds)))

(varfn path->journey-dir
  [path]
  (let [parts (path/parts (path/abspath path))
        freja-data-dir (string (os/getenv "HOME") "/.local/share/freja/journeys")
        journey-dir (string
                      freja-data-dir
                      (string/join [;(array/slice parts 0 -2)
                                    (string ".freja-journey-" (last parts))] path/sep))]
    journey-dir))

(varfn save-journey
  [path note]
  (let [journey-dir (path->journey-dir path)
        day-dir (string journey-dir path/sep (journey-date))
        journey-path (string day-dir path/sep (journey-time) " " note)]
    (reduce (fn [acc cur]
              (if-not acc
                cur
                (let [new (string acc path/sep cur)]
                  (os/mkdir new)
                  new)))
            nil
            (string/split path/sep day-dir))
    (with [f (file/open journey-path :w)]
      (with [org-f (file/open path :r)]
        (file/write f (file/read org-f :all))))

    (print "saved journey: " journey-path)))

(varfn list-backups
  [path]
  (let [journey-dir (path->journey-dir path)]
    (var days-times @[])
    (loop [dir :in (os/dir journey-dir)
           :let [full-dir (string journey-dir path/sep dir)]]
      (array/push days-times [dir
                              (seq [file :in (os/dir full-dir)]
                                (string full-dir path/sep file))]))
    days-times))


(comment

  (use freja/state)
  (->
    (get-in editor-state [:left-state :editor :gb :path])
    list-backups)
  #
)


# TODO: click to go back in time
# also make checkpoint at current point in time

(use freja/state)
(import freja/events :as e)
(import freja/theme)
(import freja/file-handling :as fh)
(import freja/render_new_gap_buffer :as rgb)

(comment
  (keys (get-in editor-state [:left-state :editor :gb]))
  #
)

(varfn format-filename
  [filename]
  (def peg
    ~{:time (/ (* ':d ':d "_")
               ,(fn [d1 d2] (string d1 d2 ":")))
      :main (* :time :time ':d ':d '(any 1))})
  (string ;(peg/match peg filename)))

(comment
  (format-filename "15_56_56 ueoh")

  #
)

(varfn show-backups
  [props]
  (def {:path path
        :textarea textarea
        :selected selected} props)

  [:background {:color (theme/colors :background)}
   [:padding {:all 6}
    [:block {}
     [:padding {:bottom 6}
      [:block {}
       [:clickable {:on-click (fn [_] (e/put! editor-state :right nil))}
        "Close"]]
      [:text {:text "Checkpoints"
              :size 28}]]]

    (try
      (let [backups (or (-?> path list-backups) [])]
        [:block {}
         [:block {}
          [:padding {:bottom 12}
           [:text {:text (string
                           "Click on checkpoints below to restore earlier versions of:\n"
                           (path/abspath path))
                   :size 18}]]]
         ;(seq [[day times] :in (reverse (sort-by first backups))]
            [:padding {:bottom 12}
             [:block {}
              [:text {:size 22
                      :text (string day)}]
              ;(seq [fullpath :in (reverse (sort times))]
                 [:clickable {:on-click
                              (fn [_]
                                (when (props :needs-save)
                                  (save-journey path "before moving to checkpoint")
                                  (:put props :needs-save false))
                                (fh/load-file textarea
                                              fullpath)
                                (put-in textarea [:gb :path] path)
                                (:put props :selected fullpath)
                                (print fullpath))}
                  [:block {}
                   [:background {:color (when (= selected fullpath)
                                          (theme/colors :text))}
                    [:text {:size 18
                            :color (when (= selected fullpath)
                                     (theme/colors :background))
                            :text (format-filename (path/basename fullpath))}]]]])]])])
      ([err fib]
        err))]])

(defn backup-component
  [props]
  (unless (props :backup-props)
    (let [backup-props
          @{:path (get-in editor-state [:left-state :editor :gb :path])
            :textarea (get-in editor-state [:left-state :editor])
            :needs-save true}]

      (put backup-props :put
           (fn [self k v]
             (e/update! props :backup-props put k v)))

      (put props :backup-props backup-props)))

  [:block {} [show-backups (props :backup-props)]])

(varfn show-checkpoints
  []
  (if-not (= (editor-state :right) backup-component)
    (e/put! editor-state :right backup-component)
    (do (put editor-state :backup-props nil)
      (e/put! editor-state :right nil))))

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

#(save-journey "journey.janet")
#(list-backups "journey.janet")
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
