import tkinter as tk
from tkinter import filedialog
import threading
import serial
import datetime
import os

def start_python_code():
    global running, ser
    running = True
    start_button.config(bg='green')
    stop_button.config(bg='red')
    arduino_com = arduino_com_entry.get()
    a_com = 'COM' + arduino_com
    ser = serial.Serial(a_com, 9600)
    status_label.config(text="Data is being logged from the reward Arduino.")
    threading.Thread(target=run_python_code).start()

def stop_python_code():
    global running, ser
    running = False
    start_button.config(bg='light green')
    stop_button.config(bg='red')
    ser.close()
    status_label.config(text="Data is no longer being logged.")

def run_python_code():
    savedir = savedir_var.get()
    dt = datetime.datetime.now()
    dt = dt.strftime("%Y%m%d_%H%M%S")
    savename = "reward_data_" + dt + ".txt"
    filename = os.path.join(savedir, savename)

    with open(filename, 'w') as f:
        while running:
            data = ser.readline().decode('utf-8').strip()
            f.write(data + '\n')

def choose_folder():
    folder = filedialog.askdirectory()
    savedir_var.set(folder)

app = tk.Tk()
app.title("Python Code Runner")

arduino_com_label = tk.Label(app, text="Arduino COM #:")
arduino_com_label.grid(row=0, column=0, sticky="e")
arduino_com_entry = tk.Entry(app)
arduino_com_entry.grid(row=0, column=1)

savedir_label = tk.Label(app, text="Save Directory:")
savedir_label.grid(row=1, column=0, sticky="e")
savedir_var = tk.StringVar()
savedir_entry = tk.Entry(app, textvariable=savedir_var)
savedir_entry.grid(row=1, column=1)

choose_folder_button = tk.Button(app, text="Choose Folder", command=choose_folder)
choose_folder_button.grid(row=1, column=2)

start_button = tk.Button(app, text="Start", bg="light green", fg="black", command=start_python_code)
start_button.grid(row=2, column=0, padx=10, pady=10)

stop_button = tk.Button(app, text="Stop", bg="red", fg="black", command=stop_python_code)
stop_button.grid(row=2, column=1, padx=10, pady=10)

status_label = tk.Label(app, text="", wraplength=300, justify='left')
status_label.grid(row=3, column=0, columnspan=3, pady=10)

running = False
ser = None

app.mainloop()