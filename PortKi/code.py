# Python code for "PortKi", which runs a touch-screen kiosk
# on an adafruit PyPortal. https://learn.adafruit.com/adafruit-pyportal
# This code is meant to read JSON and use .jpeg files of screens
# created by the PortKi app. Find out more at:
# http://github.com/gallaugher/portki
#
# Special Thanks to John Park, Scott Shawcroft for helping a newbie w/this project
# and to Limor "Lady Ada" Fried for creating PyPortal and so many other wonderful
# open-source products at adafruit.com.
# Trevor Beaton's Swift iOS tutorial made it super-easy to link an iOS app to
# Adafruit.io.
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
from adafruit_pyportal import Fake_Requests
import storage
import adafruit_sdcard
import os
import digitalio
from digitalio import DigitalInOut
import busio
import terminalio
from adafruit_display_text import label
from adafruit_bitmap_font import bitmap_font

CHECK_AFTER_MINUTES = 5
screens = []
screens_list = []
current_pageID = "Home"
# Prints version info to the Serial console
version_info = os.uname()
print(version_info)

# To use this, the user will need to update the URL below with their
# own adafruit.io account. It's free!
#
DATA_SOURCE = "https://io.adafruit.com/api/v2/gallaugher/feeds/portki/data/"

# code currently removes the portki-files directory & its contents when
# rebooted. At some point I may want to only remove updated files, but this works.
# directory = "/sd/" # sd card
directory_name = "portki-files"
directory = "/"+directory_name+"/"
LAST_DATE_CHANGED_URL = "https://portki.s3.amazonaws.com/lastDateChecked.json"

# If look in a web browser at json returned from the DATA_SOURCE url,
# you'll see json can be found inside a list value "[" after the key
# named "value"
DATA_LOCATION = [0, "value"]
# Get data from adafruit.io and also display the please wait screen,
# which should be copied to the PyPortal's default directory
pyportal = PyPortal(url=DATA_SOURCE,
                    json_path=DATA_LOCATION,
                    default_bg="/portki-system-files/portki-please-wait.bmp",)

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
        self.file_location = ""

def check_last_update():
    print("*** ATTEMPTING TO GET lastDateChecked.json")
    print("*** LAST_DATE_CHANGED_URL = ", LAST_DATE_CHANGED_URL)
    print("*** SAVING TO = ", directory+"lastDateChecked.json")
    file_not_downloaded = True
    access_attempts = 0
    # I've found the PyPortal intermittently times out. Making sure
    # there are at least 3 attempts fixes most of these occurrances from
    # causing a system crashing failure.
    while file_not_downloaded and access_attempts < 3:
        try:
            access_attempts = access_attempts + 1
            print("access attempt #:", access_attempts)
            print("LAST_DATE_CHANGED_URL =", LAST_DATE_CHANGED_URL)
            print("directory+"+"lastDateChecked.json = ",directory+"lastDateChecked.json")
            data = pyportal.wget(LAST_DATE_CHANGED_URL, directory+"lastDateChecked.json", chunk_size=250)
            print("data retrieved = :", data)
            file_not_downloaded = False
        except OSError as e:
            print("<><><><> SOME ERROR OCCURRED! -", OSError, e)
            print("For some reason couldn't read last Date Changed")
            if access_attempts > 3:
                print("*** Tried accessing", directory+"lastDateChecked.json", access_attempts,"times. Unrecoverable error.")
                print("*** Try pressing Update PyPortal from app. Also check AWSS3 is working.")
                file_not_downloaded = False
        except RuntimeError as e:
            print("<><><><> SOME ERROR OCCURRED! -", e)
            if access_attempts > 3:
                print("*** Tried accessing",directory+"lastDateChecked.json", access_attempts,"times. Unrecoverable error.")
                print("*** Try pressing Update PyPortal from app. Also check AWSS3 is working.")
                file_not_downloaded = False

# get lastDateChecked from file read from the AWSS3
fakeRequests = Fake_Requests(directory+"lastDateChecked.json").json()
jsonString = str(fakeRequests["value"])
lastDateChecked = json.loads(jsonString)["lastDateChecked"]
print(">>>>> lastDateChecked = ", lastDateChecked)
return lastDateChecked

def clear_out_directory():
    # If this is a new PyPortal there won't be a portki-files directory
    # so if one isn't found, make one
    try:
        result = os.mkdir("/"+directory_name)
    except OSError:
        print("Directory directory_name already exists - no need to make a new one")
    
    # Each re-boot deletes any files in directory_name so the freshest contents
    # is downloaded
    try:
        print("Contents of", directory, "are:")
        directory_files = os.listdir(directory)
        for file in directory_files:
            print(file)
            os.remove(directory+file)
    except OSError as e:
        print("Error:", OSError, e)
    
    free_space = os.statvfs("/")[3]
    message = "** freespace AFTER deleting files: " + str(free_space) + "KB"
    print(message)

def reload_all_data(directory):
    clear_out_directory()
    access_attempts = 0
    try_again = True
    while try_again:
        try:
            access_attempts = access_attempts + 1
            print("Trying to fetch json. Attempt #:", access_attempts)
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
            print("json successfully fetched!")
            screens_list = convertedJson
            # print("There are", len(screens_list), "screens in this kiosk.")
            screens = []
            try_again = False
        except RuntimeError as e:
            print("<><><><> SOME ERROR OCCURRED! -", e)
            if access_attempts > 3:
                print("*** Tried downloading json from", DATA_SOURCE, "a total of", access_attempts,"times. Unrecoverable error.")
                print("*** Try pressing Update PyPortal from app. Also check AWSS3 is working.")
                break
        except ValueError as e:
            print("<><><><> SOME ERROR OCCURRED! - often there is an error reading json, but it just needs another shot.", e)
            if access_attempts > 3:
                print("*** Tried downloading json from", DATA_SOURCE, "a total of", access_attempts,"times. Unrecoverable error.")
                print("*** Try pressing Update PyPortal from app. Also check AWSS3 is working.")
                break

# read_json_into_screens()
# stuff below as from reload_json_into_screens()
for i in range(len(screens_list)):
    pageID = screens_list[i]["pageID"]
    print("pageID =", pageID)
    screenURL = screens_list[i]["screenURL"]
    print("screenURL =", screens_list[i]["screenURL"])
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
        screen = Screen(pageID, buttons, screenURL)
        screens.append(screen)

    current_pageID = "Home"

for index in range(len(screens)):
    image_url = screens[index].screenURL
    print("image_url =",image_url)
    fileName = screens[index].pageID+".bmp"
    """
        print("image_url =", image_url)
        print("screens[index].screenURL =", screens[index].screenURL)
        print("Saving at:", directory + fileName)
        """
            
            # free_space will be KB free. Each images is 151KB
            free_space = os.statvfs("/")[3]
            print("Downloading screen #", index + 1, "of", len(screens))
            print("There is", free_space, "KB storage left in the PyPortal")
            if free_space < 250:
            print("*** You've run out of free space.")
            print("*** Your PyPortal only has space for", index+1, "screens.")
            print("*** Checking of sd card is available.")
            
            try:
                os.listdir("/sd")
                print(" /sd directory found!")
                print(" /sd contents: ", os.listdir("/sd"))
                # directory_name = "sd"
                    directory = "/sd/"
                except OSError as e:
                    print("<><><><> SOME ERROR OCCURRED! -", OSError, e)
                    print("You need a working sd card for your PyPortal to store more screens.")
                    print("Install an sd card and restart, or delete screens from the app, ")
                    print("press Update PyPortal, and restart.")
                    break
except RuntimeError as e:
    print("<><><><> SOME ERROR OCCURRED! -", e)
    break
        except KeyError as e:
            print("<><><><> SOME ERROR OCCURRED! -", e)
            break
        
        access_attempts = 0
        file_not_downloaded = True
        while file_not_downloaded and access_attempts < 4:
            print("image_url:", screens[index].screenURL)
            print("directory:", directory)
            print("fileName:", fileName)
            try:
                access_attempts = access_attempts + 1
                pyportal.wget(pyportal.image_converter_url(screens[index].screenURL, 320, 240, color_depth=16), directory+fileName, chunk_size=12000)
                screens[index].file_location = directory + screens[index].pageID + ".bmp"
                print(">> screen file_location for screen",screens[index].pageID ,"is", screens[index].file_location)
                file_not_downloaded = False
            except OSError as e:
                print("<><><><> SOME ERROR OCCURRED! -", OSError, e)
                print("Please restart PyPortal by pressing the Reset button on the back of the device")
            except RuntimeError as e:
                print("<><><><> SOME ERROR OCCURRED! -", e)
                print("Retrying last wget")
            # pyportal.wget(pyportal.image_converter_url(image_url,320, 240,color_depth=16), directory+fileName, chunk_size=12000)
            except KeyError as e:
                print("<><><><> SOME ERROR OCCURRED! -", e)
                print("Retrying last wget")
    # pyportal.wget(pyportal.image_converter_url(image_url,320, 240,color_depth=16), directory+fileName, chunk_size=12000)
    if access_attempts > 3:
        print("ERROR: cannot resume. Try pressing Update PyPortal in app and rebooting the PyPortal.")
        break

print("Setting background to:", directory+"Home.bmp")
pyportal.set_background(directory+"Home.bmp")

for screen in screens:
    print(screen.pageID)
    print(screen.screenURL)
    print("Screen can be accessed at", screen.file_location)
    print("This screen has", len(screen.buttons), "buttons")
    for index in range(len(screen.buttons)):
        print("  Button", index, "text =", screen.buttons[index].buttonText)
    return screens

screens = reload_all_data(directory)

lastDateChecked = check_last_update()
next_check = (CHECK_AFTER_MINUTES * 60) + time.monotonic()
print("** Current time.monotoic() = ", time.monotonic())
print("** next_check in: ", next_check)

p_list = [] # holds points indicating where a press occurred

print("><><> Screens after returning screens <><><")
for screen in screens:
    print(screen.pageID)
    print(screen.screenURL)
    print("This screen has", len(screen.buttons), "buttons")
    for index in range(len(screen.buttons)):
        print("  Button", index, "text =", screen.buttons[index].buttonText)

while True:
    
    if time.monotonic() > next_check:
        print("****** HEY! time.monotonic() > next_check ")
        print("time.monotonic() = ", time.monotonic(), "next_check = ", next_check)
        latestLastDateChecked = check_last_update()
        if latestLastDateChecked > lastDateChecked:
            # This means the app has posted data later than data on PyPortal
            print("  directory value before reload_all_data in while loop is:", directory)
            screens = reload_all_data(directory)
        next_check = (CHECK_AFTER_MINUTES * 60) + time.monotonic()

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
        print(" ><>< current_pageID = ",current_pageID)
        for screen in screens:
            if current_pageID == screen.pageID:
                print("screen.pageID = ", screen.pageID)
                print("  and it has", len(screen.buttons) ,"buttons")
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
                        download_location = ""
                        try:
                            for x in range(len(screens)):
                                if current_pageID == screens[x].pageID:
                                    download_location = screens[x].file_location
                                    print("  Moving to screen:",current_pageID)
                                    print("   which should be at location", screens[x].file_location)
                                    print("   the file location for screen:", screens[x].pageID)
                            print("download_location = ", download_location)
                            pyportal.set_background(download_location)
                        except OSError as e:
                            # TODO: print this error to PyPortal screen.
                            print("*** Error getting image from", directory+current_pageID)
                            print("*** Please turn device over and press the Reset button")
                            print("*** If this doesn't work, open the PortKi app and select:")
                            print("***     Update PyPortal   ***")
                            # Line below will reset things back to home screen
                            # if there is a problem. Not the best UX, but better
                            # than a screen-of-death
                            pyportal.set_background(directory+"Home.bmp")
                        break
            if break_outer_loop:
                break
    
        # sleap to avoid pressing two buttons on accident
        time.sleep(.5)
        # clear p
    p_list = []
