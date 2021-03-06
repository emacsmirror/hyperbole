;;; kotl-mode-tests.el --- kotl-mode-el tests            -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Mats Lidell

;; Author: Mats Lidell <matsl@gnu.org>
;;
;; Orig-Date: 18-May-21 at 22:14:10
;;
;; Copyright (C) 2021  Free Software Foundation, Inc.
;; See the "HY-COPY" file for license information.
;;
;; This file is part of GNU Hyperbole.

;;; Commentary:

;; Tests for kotl-mode in "../kotl/kotl-mode.el"

;;; Code:

(require 'ert)
(require 'kotl-mode)

(load (expand-file-name "hy-test-helpers"
                        (file-name-directory (or load-file-name
                                                 default-directory))))
(declare-function hy-test-helpers:consume-input-events "hy-test-helpers")

(defmacro setup-kotl-mode-example-test (&rest body)
  "Setup for test using kotl-mode:example and run BODY."
  `(unwind-protect
       (progn
         ,@body
         (should (equal major-mode 'kotl-mode))
         (should (string= (buffer-name (current-buffer)) "EXAMPLE.kotl")))
     (kill-buffer "EXAMPLE.kotl")))

(ert-deftest smart-menu-loads-kotl-example ()
  "Loading kotl-mode example file works."
  (skip-unless (not noninteractive))
  (setup-kotl-mode-example-test
   (should (hact 'kbd-key "C-h h k e"))
   (hy-test-helpers:consume-input-events)))

(ert-deftest kotl-mode-example-loads-kotl-example ()
  "Loading kotl-mode example file works."
  (setup-kotl-mode-example-test
   (kotl-mode:example)))

(ert-deftest kotl-mode-move-between-cells ()
  "Loading kotl-mode example file works."
  (setup-kotl-mode-example-test
   ;; Start in first cell
   (kotl-mode:example temporary-file-directory t)
   (kotl-mode:beginning-of-buffer)
   (should (kotl-mode:first-cell-p))

   ;; Move to next cell
   (kotl-mode:next-cell 1)
   (should (not (kotl-mode:first-cell-p)))
   (should (equal (kcell-view:level) 1))
   (should (string= (kcell-view:visible-label) "2"))

   ;; Move to next cell
   (kotl-mode:next-cell 1)
   (should (not (kotl-mode:first-cell-p)))
   (should (equal (kcell-view:level) 2))
   (should (string= (kcell-view:visible-label) "2a")))
  )

(ert-deftest kotl-mode-indent-cell-changes-level ()
  "Loading kotl-mode example file works."
  (skip-unless (not noninteractive))
  (setup-kotl-mode-example-test
   (kotl-mode:example temporary-file-directory t)
   (kotl-mode:beginning-of-buffer)
   (should (kotl-mode:first-cell-p))
   (kotl-mode:next-cell 1)
   (should (hact 'kbd-key "TAB"))
   (hy-test-helpers:consume-input-events)
   (should (equal (kcell-view:level) 2))
   (should (string= (kcell-view:visible-label) "1a"))
   ;; Cleanup
   (set-buffer-modified-p nil)))

(ert-deftest kotl-mode-extension-open-buffer-in-kotl-mode ()
  "When a file with kotl extension is created it enters kotl mode."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl" "hej")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (should (equal major-mode 'kotl-mode)))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-set-view-with-kbd ()
  "When the view mode is changed the label is changed too."
  (skip-unless (not noninteractive))
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (should (string= (kcell-view:label (point)) "1"))
          (should (hact 'kbd-key "C-c C-v 0 RET"))
          (hy-test-helpers:consume-input-events)
          (should (eq (kview:label-type kview) 'id))
          (should (string= (kcell-view:label (point)) "01")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-idstamp-saved-with-file ()
  "The active view mode is saved with the buffer."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)

          ;; Verify default label
          (should (string= (kcell-view:label (point)) "1"))

          ;; Verify idstamp label
          (kvspec:activate "ben0")
          (should (eq (kview:label-type kview) 'id))
          (should (string= (kcell-view:idstamp) "01"))
          (should (string= (kcell-view:label (point)) "01"))

          ;; Verify idstamp view is active when file is visited next time.
          (set-buffer-modified-p t)
          (save-buffer)
          (kill-buffer)
          (find-file kotl-file)
          (should (eq (kview:label-type kview) 'id))
          (should (string= (kcell-view:idstamp) "01"))
          (should (string= (kcell-view:label (point)) "01")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-demote-keeps-idstamp ()
  "When tree is demoted the idstamp label is not changed."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (kotl-mode:add-cell)

          ;; Verify default label
          (should (string= (kcell-view:idstamp) "02"))
          (should (string= (kcell-view:label (point)) "2"))

          ;; Verify idstamp label
          (kvspec:activate "ben0")
          (should (string= (kcell-view:idstamp) "02"))
          (should (string= (kcell-view:label (point)) "02"))

          ;; Verify demote does not change idstamp label
          (kotl-mode:demote-tree 0)
          (should (string= (kcell-view:idstamp) "02"))
          (should (string= (kcell-view:label (point)) "02")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-demote-change-label ()
  "When tree is demoted the label is changed."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (kotl-mode:add-cell)

          ;; Verify default label
          (should (string= (kcell-view:label (point)) "2"))

          ;; Verify demote change label
          (kotl-mode:demote-tree 0)
          (should (string= (kcell-view:label (point)) "1a")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-label-type-activation ()
  "Kotl-mode test label type activation."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (kotl-mode:add-cell)
          (kotl-mode:demote-tree 0)

          (should (string= (kcell-view:label (point)) "1a"))

          (kvspec:activate "ben.")
          (should (string= (kcell-view:label (point)) "1.1"))

          (kvspec:activate "ben0")
          (should (string= (kcell-view:label (point)) "02")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-move-cell-before-cell ()
  "Move cell before cell."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (insert "first")
          (kotl-mode:add-cell)
          (insert "second")

          (kotl-mode:move-before "2" "1" nil)
          (kotl-mode:beginning-of-buffer)

          (should (string= (kcell-view:label (point)) "1"))
          (should (looking-at-p "second")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-move-cell-after-cell ()
  "Move cell after cell."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (insert "first")
          (kotl-mode:add-cell)
          (insert "second")

          (kotl-mode:beginning-of-buffer)
          (kotl-mode:move-after "1" "2" nil)

          (should (string= (kcell-view:label (point)) "2"))
          (should (looking-at-p "first")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-copy-cell-after-cell ()
  "Copy cell after cell."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (insert "first")
          (kotl-mode:add-cell)
          (insert "second")

          (kotl-mode:beginning-of-buffer)
          (kotl-mode:copy-after "1" "2" nil)

          (should (string= (kcell-view:label (point)) "3"))
          (should (looking-at-p "first")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-copy-cell-before-cell ()
  "Copy cell after cell."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (insert "first")
          (kotl-mode:add-cell)
          (insert "second")

          (kotl-mode:copy-before "2" "1" nil)

          (should (string= (kcell-view:label (point)) "1"))
          (should (looking-at-p "second")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-jump-to-cell ()
  "Kotl-mode jump to cell."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (kotl-mode:add-cell)

          (kotl-mode:goto-cell "1")
          (should (string= (kcell-view:label (point)) "1"))

          (kotl-mode:goto-cell "2")
          (should (string= (kcell-view:label (point)) "2")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-goto-child-and-parent ()
  "Kotl-mode goto child and goto parent."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (kotl-mode:add-child)

          (should (string= (kcell-view:label (point)) "1a"))

          (kotl-mode:up-level 1)
          (should (string= (kcell-view:label (point)) "1"))

          (kotl-mode:down-level 1)
          (should (string= (kcell-view:label (point)) "1a")))
      (delete-file kotl-file))))

(ert-deftest kotl-mode-kill-cell ()
  "Kotl-mode kill a cell test."
  (let ((kotl-file (make-temp-file "hypb" nil ".kotl")))
    (unwind-protect
        (progn
          (find-file kotl-file)
          (insert "first")
          (kotl-mode:add-child)
          (should (string= (kcell-view:label (point)) "1a"))

          (kotl-mode:kill-tree)
          (should (string= (kcell-view:label (point)) "1"))
          (kotl-mode:beginning-of-cell)
          (should (looking-at-p "first"))

          (kotl-mode:kill-tree)
          (kotl-mode:beginning-of-cell)
          (should (looking-at-p "$")))
      (delete-file kotl-file))))

(provide 'kotl-mode-tests)
;;; kotl-mode-tests.el ends here



