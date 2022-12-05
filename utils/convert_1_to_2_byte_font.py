#!/usr/bin/env python3

def main():
    with open("font_small_1152_14.data", "rb") as f1, open("res_font_small_1152_14.data", "wb") as f2:
        while bytes := f1.read(1):
            f2.write(bytes)
            f2.write(b'\xFF')




if __name__ == "__main__":
    main()
