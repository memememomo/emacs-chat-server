;;; websocket-chat.el ---

;; Copyright (C) 2012 by Uchico

;; Author: Uchico <memememomo@gmail.com>
;; URL:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'cl))

(require 'websocket)


(defvar wsc-websocket)
(defvar wsc-chat-buffer)
(defvar wsc-host)
(defvar wsc-port)
(defvar wsc-path)
(defvar wsc-username)


(defun wsc-read-config ()
  (setq wsc-host (read-string "host: "))
  (setq wsc-port (read-number "port: "))
  (setq wsc-path (read-string "path: "))
  (setq wsc-username (read-string "username: ")))

(defun wsc-init-window ()
  (setq wsc-chat-buffer (get-buffer-create "*wsc-chat*"))
  (switch-to-buffer wsc-chat-buffer))

(defun wsc-init-websocket ()
  (setq wsc-websocket
		(websocket-open
		 (format "ws://%s:%s%s" wsc-host wsc-port wsc-path)
		 :on-message (lambda (websocket frame)
					   (with-current-buffer wsc-chat-buffer
						 (end-of-buffer)
						 (insert (format "%s\n" (websocket-frame-payload frame)))))
		 :on-error (lambda (ws type err)
					 (message (format "%s:%s" type err)))
		 :on-close (lambda (websocket) (setq wstest-closed t)))))

(defun wsc-main-loop ()
  (setq msg (read-string "Msg:"))
  (wsc-send-to-server (format "%s: %s" wsc-username msg))
  (wsc-main-loop))


(defun wsc-send-to-server (msg)
  (websocket-send-text wsc-websocket
					   (encode-coding-string msg 'raw-text)))

(defun wsc-init ()
  (wsc-read-config)
  (wsc-init-window)
  (wsc-init-websocket)
  (wsc-main-loop))

(defun wsc-finalize ()
  (websocket-close wsc-websocket))

(defun websocket-chat-start ()
  (interactive)
  (wsc-init)
)


(provide 'websocket-chat)


;;;; websocket-chat.el ends here