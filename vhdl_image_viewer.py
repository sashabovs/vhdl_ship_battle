#!/usr/bin/env python3

import time
import tkinter
from tkinter import *


class MainWindow(Tk):
    def __init__(self):
        super().__init__()
        self.is_closed = False

        self.title("VHDL screen viewer")

        self.rowconfigure(0, weight=1)
        self.columnconfigure(1, weight=1)
        frame1 = LabelFrame(self, text="Options", padx=15, pady=15)
        frame1.grid(row=0, column=0, sticky="news")

        opt_row = 0
        lc = Label(frame1, text="Scale:")
        lc.grid(row=opt_row, column=0)
        self.entry_scale = StringVar()
        self.entry_scale.set("10")
        Spinbox(frame1, from_=1, to=20, increment=1, textvariable=self.entry_scale).grid(
            row=opt_row, column=1
        )

        opt_row += 1
        lc = Label(frame1, text="Sleep, s:")
        lc.grid(row=opt_row, column=0)
        self.entry_sleep = StringVar()
        self.entry_sleep.set("1")
        Spinbox(frame1, from_=0.1, to=10, increment=0.1, textvariable=self.entry_sleep).grid(
            row=opt_row, column=1
        )

        opt_row += 1
        lc = Label(frame1, text="Show pixels:")
        lc.grid(row=opt_row, column=0)
        self.show_pixels = IntVar()
        show_pixels_elem = Checkbutton(frame1, variable=self.show_pixels, padx=0)
        show_pixels_elem.grid(row=opt_row, column=1, sticky="w")

        opt_row += 1
        bCalc = Button(frame1, text="Calc", command=self.calcClick)
        bCalc.grid(row=opt_row, column=0, columnspan=2)

        opt_row += 1
        lc = Label(frame1, text="Frame number:")
        lc.grid(row=opt_row, column=0)
        self.entry_frame_num_var = StringVar()
        entry_frame_num = Entry(frame1, state=DISABLED, textvariable=self.entry_frame_num_var)
        entry_frame_num.grid(row=opt_row, column=1)

        col_count, row_count = frame1.grid_size()

        for row in range(row_count):
            frame1.rowconfigure(row, pad=25)

        frameCanvas = LabelFrame(self, text="Screen", padx=15, pady=15)
        frameCanvas.grid(row=0, column=1, sticky="news")

        self.canvas = Canvas(frameCanvas)
        self.canvas.pack(fill=BOTH, expand=1)

        self.geometry("1600x1100")

    def set_text(self, entry, text):
        entry.delete(0, END)
        entry.insert(0, text)

    def calcClick(self):
        i = 0
        while True and not self.is_closed:
            i += 1
            scale = 10
            try:
                scale = int(self.entry_scale.get())
            except Exception:
                self.entry_scale.set(str(scale))
                pass

            sleep = 1
            try:
                sleep = float(self.entry_sleep.get())
            except Exception:
                self.entry_sleep.set(str(sleep))
                pass

            try:
                with open("test_rgb.bin", "rb") as f:
                    w = int.from_bytes(f.read(2), "big")
                    h = int.from_bytes(f.read(2), "big")
                    x = y = 0
                    frame_num = 0
                    self.entry_frame_num_var.set(str(frame_num))
                    while bytes := f.read(3):
                        if x == 0 and y == 0:
                            self.canvas.delete("all")
                        self.canvas.create_rectangle(
                            x * scale,
                            y * scale,
                            x * scale + scale - 1,
                            y * scale + scale - 1,
                            fill=f"#{bytes.hex()}",
                            outline="#999999" if self.show_pixels.get() else f"#{bytes.hex()}",
                        )
                        x += 1
                        if x == w:
                            x = 0
                            y += 1
                        if y == h:
                            y = 0
                            self.update()
                            time.sleep(sleep)
                            frame_num += 1
                            self.entry_frame_num_var.set(str(frame_num))
                    self.update()
                    time.sleep(sleep)

            except Exception as e:
                pass


def on_closing(app):
    app.is_closed = True
    app.destroy()


def main():
    app = MainWindow()
    app.protocol("WM_DELETE_WINDOW", lambda: on_closing(app))
    app.bind("<Escape>", lambda e: on_closing(app))
    app.mainloop()


if __name__ == "__main__":
    main()
