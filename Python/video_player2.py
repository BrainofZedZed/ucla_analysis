import cv2
import tkinter as tk
from tkinter import filedialog

class VideoPlayer:
    def __init__(self, window):
        self.window = window
        self.window.title("Video Player")

        # Video properties
        self.video_path = None
        self.video_cap = None
        self.total_frames = 0
        self.current_frame = 0

        # GUI elements
        self.frame_label = tk.Label(window, text="Frame: 0")
        self.frame_label.pack()

        self.load_button = tk.Button(window, text="Load Video", command=self.load_video)
        self.load_button.pack()

        self.play_button = tk.Button(window, text="Play", command=self.play_video)
        self.play_button.pack()

        self.pause_button = tk.Button(window, text="Pause", command=self.pause_video)
        self.pause_button.pack()

        self.jump_entry = tk.Entry(window)
        self.jump_entry.pack()

        self.jump_button = tk.Button(window, text="Jump to Frame", command=self.jump_to_frame)
        self.jump_button.pack()

        self.skip_forward_button = tk.Button(window, text="Skip Forward 50 Frames", command=self.skip_forward)
        self.skip_forward_button.pack()

        self.skip_back_button = tk.Button(window, text="Skip Back 50 Frames", command=self.skip_back)
        self.skip_back_button.pack()

        # Resize event
        self.window.bind("<Configure>", self.resize_window)

    def load_video(self):
        self.video_path = filedialog.askopenfilename(filetypes=[("Video Files", "*.mp4 *.avi *.mkv *.mov")])

        if self.video_path:
            self.video_cap = cv2.VideoCapture(self.video_path)
            self.total_frames = int(self.video_cap.get(cv2.CAP_PROP_FRAME_COUNT))
            self.update_frame_label(0)

    def play_video(self):
        if self.video_cap:
            while True:
                ret, frame = self.video_cap.read()
                if not ret:
                    break

                cv2.imshow("Video Player", frame)
                if cv2.waitKey(1) & 0xFF == 27:  # Press 'Esc' to stop playing
                    break

            self.video_cap.release()
            cv2.destroyAllWindows()
            self.update_frame_label(0)

    def pause_video(self):
        if self.video_cap:
            self.video_cap.release()

    def jump_to_frame(self):
        if self.video_cap and self.jump_entry.get().isdigit():
            target_frame = int(self.jump_entry.get())
            if 0 <= target_frame < self.total_frames:
                self.video_cap.set(cv2.CAP_PROP_POS_FRAMES, target_frame)
                self.update_frame_label(target_frame)

    def skip_forward(self):
        if self.video_cap:
            new_frame = min(self.current_frame + 50, self.total_frames - 1)
            self.video_cap.set(cv2.CAP_PROP_POS_FRAMES, new_frame)
            self.update_frame_label(new_frame)

    def skip_back(self):
        if self.video_cap:
            new_frame = max(self.current_frame - 50, 0)
            self.video_cap.set(cv2.CAP_PROP_POS_FRAMES, new_frame)
            self.update_frame_label(new_frame)

    def update_frame_label(self, frame_number):
        self.current_frame = frame_number
        self.frame_label.config(text="Frame: {}".format(frame_number))

    def resize_window(self, event):
        if self.video_cap:
            ret, frame = self.video_cap.read()
            if ret:
                cv2.imshow("Video Player", cv2.resize(frame, (event.width, event.height)))


if __name__ == "__main__":
    root = tk.Tk()
    player = VideoPlayer(root)
    root.mainloop()
