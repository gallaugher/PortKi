# Python code for "PortKi", which runs a touch-screen kiosk
# on an adafruit PyPortal. https://learn.adafruit.com/adafruit-pyportal
# This code is meant to read JSON and use .jpeg files of screens
# created by the PortKi app. Find out more at:
# http://github.com/gallaugher/portki
#
# Special Thanks to John Park, Scott Shawcroft for helping a newbie w/this project
# and to Limor "Lady Ada" Fried for creating PyPortal and so many other wonderful
# open-source products at adafruit.com.
# Comments? Find me at twitter: @gallaugher
# Projects & tutorials at: YouTube: bit.ly/GallaugherYouTube
# and the web: gallaugher.com
#
# Also note, the code below has a bunch of print statements that are
# commented out. These are useful for debugging, and to help new users
# understand what's happening in the code. Removing the hashtags will
# print results to the PyPortal's Serial console in Mu, when the PyPortal
# is plugged into the same machine running Mu.

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
import terminalio
from adafruit_display_text import label
from adafruit_bitmap_font import bitmap_font

# Prints version info to the Serial console
version_info = os.uname()
print(version_info)

# To use this, the user will need to update the URL below with their
# own adafruit.io account. It's free!
#
DATA_SOURCE = "https://io.adafruit.com/api/v2/gallaugher/feeds/portki/data/"

# code currently removes the portki-files directory & its contents when
# rebooted. At some point I may want to only remove updated files, but this works.
# DIRECTORY = "/sd/" # sd card
DIRECTORY_NAME = "portki-files"
DIRECTORY = "/"+DIRECTORY_NAME+"/"

# If this is a new PyPortal there won't be a portki-files directory
# so if one isn't found, make one
try:
    result = os.mkdir("/"+DIRECTORY_NAME)
except OSError:
    print("Directory DIRECTORY_NAME already exists - no need to make a new one")

# Each re-boot deletes any files in DIRECTORY_NAME so the freshest contents
# is downloaded
try:
    print("Contents of", DIRECTORY, "are:")
    directory_files = os.listdir(DIRECTORY)
    for file in directory_files:
        print(file)
        os.remove(DIRECTORY+file)
except OSError as e:
    print("Error:", OSError, e)

free_space = os.statvfs("/")[3]
message = "** freespace AFTER deleting files: " + str(free_space) + "KB"
print(message)

# If look in a web browser at json returned from the DATA_SOURCE url,
# you'll see json can be found inside a list value "[" after the key
# named "value"
DATA_LOCATION = [0, "value"]
# Get data from adafruit.io and also display the please wait screen,
# which should be copied to the PyPortal's default directory
pyportal = PyPortal(url=DATA_SOURCE,
                    json_path=DATA_LOCATION,
                    default_bg="portki-please-wait.bmp",)

print(message)
# display_message(message)
# pyportal.set_text("Hello there!", 0)

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
    def __init__(self, pageID, buttons, screenURL):
        self.pageID = pageID
        self.buttons = buttons
        self.screenURL = screenURL

def display_message(message):
    display = board.DISPLAY
    # Set text, font, and color
    text = "HELLO WORLD"
    font = terminalio.FONT
    color = 0x0000FF
    # Create the tet label
    text_area = label.Label(font, text=message, color=0x00FF00)
    # Set the location
    text_area.x = 20
    text_area.y = 40
    # Show it
    display.show(text_area)

def read_json_into_screens():
    for i in range(len(screens_list)):
        pageID = screens_list[i]["pageID"]
        # print("pageID =", pageID)
        screenURL = screens_list[i]["screenURL"]
        # print("screenURL =", screens_list[i]["screenURL"])
        num_of_buttons = len(screens_list[i]["buttons"])
        # print("This page has", num_of_buttons, "buttons")
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
        screen = Screen(pageID, buttons, screenURL)
        screens.append(screen)

"""
    for screen in screens:
    print(screen.pageID)
    print(screen.screenURL)
    print("This screen has", len(screen.buttons), "buttons")
    for index in range(len(screen.buttons)):
    print("  Button", index, "text =", screen.buttons[index].buttonText)
    print("  Button", index, "buttonDestination =", screen.buttons[index].buttonDestination)
    print("  Button", index, "has coordinates:", screen.buttons[index].x, screen.buttons[index].y, screen.buttons[index].width, screen.buttons[index].height)
    """

try:
    response = pyportal.fetch()
    """
        print("%%%% JSON RETRIEVED %%%%")
        print("??? Len of response: ", len(response))
        print("*** PRINTING response:\n", response, "\n")
        print("*** response is of type:\n", type(response), "\n")
        """
    convertedJson = json.loads(response)
    """
        print("*** convertedJson is of type:\n", type(convertedJson), "\n")
        print("*** PRINTING convertedJson:\n", convertedJson, "\n")
        print(convertedJson[0]["pageID"])
        """
    screens_json = convertedJson
    screens_list = screens_json
    # print("There are", len(screens_list), "screens in this kiosk.")
    screens = []
except RuntimeError as e:
    print("<><><><> SOME ERROR OCCURRED! -", e)

"""
    # Stuff below shows green text on black background but won't clear for subsequent .set_background() calls.
    display = board.DISPLAY
    # Set text, font, and color
    text = "HELLO WORLD"
    font = terminalio.FONT
    color = 0x0000FF
    # Create the tet label
    text_area = label.Label(font, text=message, color=0x00FF00)
    # Set the location
    text_area.x = 20
    text_area.y = 20
    # Show it
    display.show(text_area)
    """

read_json_into_screens()
current_pageID = "Home"

screen_count = 0
for screen in screens:
    image_url = screen.screenURL
    fileName = screen.pageID+".bmp"
    # print("image_url =", image_url)
    # print("screen.screenURL =", screen.screenURL)
    # print("Saving at:", DIRECTORY+fileName)
    
    # free_space will be KB free. Each images is 151KB
    free_space = os.statvfs("/")[3]
    print("Downloading screen #", screen_count)
    print("There is", free_space, "KB storage left in the PyPortal")
    if free_space < 250:
        print("*** You've run out of free space.")
        print("*** Your PyPortal only has space for", screen_count, "screens.")
        break
    else:
        try:
            screen_count = screen_count + 1
            pyportal.wget(pyportal.image_converter_url(image_url,320, 240,color_depth=16), DIRECTORY+fileName, chunk_size=12000)
        except OSError as e:
            print("<><><><> SOME ERROR OCCURRED! -", OSError, e)
            print("Please restart PyPortal by pressing the Reset button on the back of the device")
        except RuntimeError as e:
            print("<><><><> SOME ERROR OCCURRED! -", e)
            print("Retrying last wget")
            pyportal.wget(pyportal.image_converter_url(image_url,320, 240,color_depth=16), DIRECTORY+fileName, chunk_size=12000)

print("Setting background to:", DIRECTORY+"Home.bmp")
pyportal.set_background(DIRECTORY+"Home.bmp")

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
                    if ( left_side <= x and right_side >= x ) and ( top_side <= y and bottom_side >= y ):
                        print("***** TOUCH DETECTED ***** inside button ", screen.buttons[index].buttonText)
                        break_outer_loop = True
                        current_pageID = screen.buttons[index].buttonDestination
                        print("Time to load screen", current_pageID)
                        try:
                            pyportal.set_background(DIRECTORY+current_pageID+".bmp")
                        except OSError as e:
                            # TODO: print this error to PyPortal screen.
                            print("*** Error getting image from", DIRECTORY+current_pageID)
                            print("*** Please turn device over and press the Reset button")
                            print("*** If this doesn't work, open the PortKi app and select:")
                            print("***     Update PyPortal   ***")
                        break
            if break_outer_loop:
                break

# sleap to avoid pressing two buttons on accident
time.sleep(.5)
# clear p
    p_list = []
