import cv2
import tkinter as tk
from tkinter import filedialog

class VideoPlayer:
    def __init__(self):
        self.window = tk.Tk()
        self.window.title("Video Player")

        self.video_path = ""
        self.video_cap = None
        self.playing = False
        self.speed = 1.0

        self.canvas = tk.Canvas(self.window)
        self.canvas.pack()

        self.scrollbar = tk.Scrollbar(self.window, command=self.on_scroll)
        self.scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.load_button = tk.Button(self.window, text="Load", command=self.load_video)
        self.load_button.pack(side=tk.LEFT)

        self.start_button = tk.Button(self.window, text="Start", command=self.start_video)
        self.start_button.pack(side=tk.LEFT)

        self.stop_button = tk.Button(self.window, text="Stop", command=self.stop_video)
        self.stop_button.pack(side=tk.LEFT)

        self.window.mainloop()

    def load_video(self):
        self.video_path = filedialog.askopenfilename(filetypes=[("Video Files", "*.mp4;*.avi;*.mkv")])
        if self.video_path:
            self.video_cap = cv2.VideoCapture(self.video_path)
            self.scrollbar.config(to=self.video_cap.get(cv2.CAP_PROP_FRAME_COUNT))

    def start_video(self):
        if self.video_cap and not self.playing:
            self.playing = True
            self.play_video()

    def stop_video(self):
        self.playing = False

    def play_video(self):
        if not self.playing:
            return

        ret, frame = self.video_cap.read()
        if ret:
            frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frame = cv2.resize(frame, (self.canvas.winfo_width(), self.canvas.winfo_height()))

            image = tk.PhotoImage(data=cv2.imencode(".png", frame)[1].tobytes())
            self.canvas.create_image(0, 0, anchor=tk.NW, image=image)
            self.canvas.image = image

            delay = int(1000 / (self.speed * 30))  # Assuming 30 frames per second
            self.window.after(delay, self.play_video)
        else:
            self.playing = False

    def on_scroll(self, *args):
        if self.video_cap:
            frame_number = int(self.scrollbar.get())
            self.video_cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)

if __name__ == "__main__":
    VideoPlayer()
