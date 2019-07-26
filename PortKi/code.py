# NOTE: This version temporarily broken as I test wget. Will post working v. soon.
import time
import json
import board
import adafruit_touchscreen
from adafruit_pyportal import PyPortal
import storage
import adafruit_sdcard
import os
import digitalio
import busio
"""
    # Use stuff below when working with the PyPortal's microSD card
    spi = busio.SPI(board.SCK, MOSI=board.MOSI, MISO=board.MISO)
    cs = digitalio.DigitalInOut(board.SD_CS)
    sdcard = adafruit_sdcard.SDCard(spi, cs)
    vfs = storage.VfsFat(sdcard)
    storage.mount(vfs, "/sd")
    print(os.listdir('/sd'))
    """

"""
    # See if a card is present
    card_detect_pin = digitalio.DigitalInOut(board.SD_CARD_DETECT)
    card_detect_pin.direction = digitalio.Direction.INPUT
    card_detect_pin.pull = digitalio.Pull.UP
    print('SD card present: %s' % card_detect_pin.value)
    
    # Try to connect to the SD card
    sdcard = adafruit_sdcard.SDCard(
    busio.SPI(board.SCK, board.MOSI, board.MISO),
    digitalio.DigitalInOut(board.SD_CS)
    )
    # Mount the card to a directory
    virtual_file_system = storage.VfsFat(sdcard)
    storage.mount(virtual_file_system, '/sd')
    """

# pyportal = PyPortal(default_bg="Home.bmp",)

DATA_SOURCE = "https://io.adafruit.com/api/v2/gallaugher/feeds/portkijsondemo/data/"
num = 0

DATA_LOCATION = [0, "value"]
URL_PATH = "https://cdn-shop.adafruit.com/310x233/4116-00.jpeg"

pyportal = PyPortal(url=DATA_SOURCE,
                    json_path=DATA_LOCATION,
                    default_bg="Home.bmp",)

# to get direct, usable link to a jpeg publically accessible on a google drive
# first get the sharable link, then copy the long ID from this link &
# paste it into the URL string following: https://drive.google.com/uc?

# below is direct image to a jpeg
image_url = "https://drive.google.com/uc?id=1Ixv3QGuc8Yk8WhxRyjY0RP39huszKvCY"

# below is a direct image to a bmp, there doesn't seem to be any speed adv.
# to using a .bmp over a .jpeg
# image_url = "https://drive.google.com/uc?id=1UllzeBmeRMw-Tb6dHX3OoAC54f2rP1lY"

pyportal.image_url_path = URL_PATH

pyportal.wget(pyportal.image_converter_url(image_url,320, 240,color_depth=16),
              "imageFromWeb.bmp",
              chunk_size=12000)

pyportal.set_background("imageFromWeb.bmp")

p_list = [] # holds points indicating where a press occurred
# These pins are used as both analog and digital! XL, XR and YU must be analog
# and digital capable. YD just need to be digital
ts = adafruit_touchscreen.Touchscreen(board.TOUCH_XL, board.TOUCH_XR,
                                      board.TOUCH_YD, board.TOUCH_YU,
                                      calibration=((5200, 59000), (5800, 57000)),
                                      size=(320, 240))
class Button:
    def __init__(self, buttonText, buttonDestination, x, y, width, height):
        self.buttonText = buttonText
        self.buttonDestination = buttonDestination
        self.x = x
        self.y = y
        self.width = width
        self.height = height

class Screen:
    def __init__(self, pageID, buttons):
        self.pageID = pageID
        self.buttons = buttons

def read_json_into_screens():
    for i in range(len(screens_list)):
        pageID = screens_list[i]["pageID"]
        num_of_buttons = len(screens_list[i]["buttons"])
        print("This page has", num_of_buttons, "buttons")
        buttons = []
        for button_index in range(num_of_buttons):
            buttonText = screens_list[i]["buttons"][button_index]["text"]
            buttonDestination = screens_list[i]["buttons"][button_index]["buttonDestination"]
            x = screens_list[i]["buttons"][button_index]["buttonCoordinates"]["x"]
            y = screens_list[i]["buttons"][button_index]["buttonCoordinates"]["y"]
            width = screens_list[i]["buttons"][button_index]["buttonCoordinates"]["width"]
            height = screens_list[i]["buttons"][button_index]["buttonCoordinates"]["height"]
            button = Button(buttonText, buttonDestination, x, y, width, height)
            buttons.append(button)
        screen = Screen(pageID, buttons)
        screens.append(screen)
    
    for screen in screens:
        print(screen.pageID)
        print("This screen has", len(screen.buttons), "buttons")
        for index in range(len(screen.buttons)):
            print("  Button", index, "text =", screen.buttons[index].buttonText)
            print("  Button", index, "buttonDestination =", screen.buttons[index].buttonDestination)
            print("  Button", index, "has coordinates:", screen.buttons[index].x, screen.buttons[index].y, screen.buttons[index].width, screen.buttons[index].height)

try:
    response = pyportal.fetch()
    print("%%%% JSON RETRIEVED %%%%")
    print("??? Len of response: ", len(response))
    print("*** PRINTING response:\n", response, "\n")
    print("*** response is of type:\n", type(response), "\n")
    convertedJson = json.loads(response)
    print("*** convertedJson is of type:\n", type(convertedJson), "\n")
    print("*** PRINTING convertedJson:\n", convertedJson, "\n")
    #    print(convertedJson["screens"][0]["pageID"])
    print(convertedJson[0]["pageID"])
    screens_json = convertedJson
    
    #    screens_list = screens_json["screens"]
    screens_list = screens_json
    print("There are", len(screens_list), "screens in this kiosk.")
    screens = []

except RuntimeError as e:
    print("<><><><> SOME ERROR OCCURRED! -", e)

read_json_into_screens()
current_pageID = "Home"

while True:
    p = ts.touch_point
    
    if p:
        print("p = ", p)
        # append each touch connection to a list
        # I had an issue with the first touch detected not being accurate
        p_list.append(p)
        
        #affter three trouch detections have occured.
        if len(p_list) == 3:
            
            #discard the first touch detection and average the other two get the x,y of the touch
            x = (p_list[1][0]+p_list[2][0])/2
        y = (p_list[1][1]+p_list[2][1])/2
        print("!!! TOUCH DETECTED: ", x, y)
        current_touch_point = (x, y)
        # handle_start_press((x, y))

        break_outer_loop = False
        for screen in screens:
            
            if current_pageID == screen.pageID:
                for index in range(len(screen.buttons)):
                    left_side = screen.buttons[index].x
                    right_side = screen.buttons[index].x + screen.buttons[index].width
                    top_side = screen.buttons[index].y
                    bottom_side = screen.buttons[index].y + screen.buttons[index].height
                    #                print(screen.buttons[index].buttonText, "coordinates", left_side, right_side, top_side, bottom_side)
                    if ( left_side <= x and right_side >= x ) and ( top_side <= y and bottom_side >= y ):
                        print("***** TOUCH DETECTED ***** inside button ", screen.buttons[index].buttonText)
                        break_outer_loop = True
                        current_pageID = screen.buttons[index].buttonDestination
                        print("Time to load screen", current_pageID)
                        pyportal.set_background(current_pageID+".bmp")
                        break
            if break_outer_loop:
                break

# sleap to avoid pressing two buttons on accident
time.sleep(.5)
# clear p
    p_list = []
