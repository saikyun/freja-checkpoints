# freja-checkpoints

to try it:

```
cd ~/.config/freja
git clone https://github.com/saikyun/freja-checkpoints
freja init.janet
```

then in your init.janet put:

```
# might need to tweak imports according to your taste
(import freja/file-handling :as fh)
(use freja/default-hotkeys)
(import freja/state)

(import ./freja-checkpoints/journey)

(global-set-key [:control :shift :i]
                (fn [_] (journey/show-checkpoints)))

(defn save-file
  [props &opt note]
  (print "journey save")

  (default note "manual save")

  (def path (tracev (props :path)))

  (fh/save-file props)
  (journey/save-journey path note))

(varfn load-file
  [props path]

  (tracev path)
  (pp (keys props))

  (save-file (props :gb) (string "before opening " path))
  (fh/load-file props path))

(varfn state/quit-hook
  []
  (save-file (get-in state/editor-state [:left-state :editor :gb]) "before quitting"))

(global-set-key [:control :s] save-file)
(set-key file-open-binds [:load-file] load-file)
```
