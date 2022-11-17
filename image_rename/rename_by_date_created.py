from PIL import Image
import sys
import os
import datetime as dt
import ffmpeg
from dateutil import parser


def get_date_taken():
    path = sys.argv[1]
    for root, dirs, files in os.walk(path):
        if root == '.':
            for image in files:
                try:
                    if 'jpg' in image.lower():
                        print(root, image)
                        im = Image.open(image)
                        created_at = im.getexif().get(36867)
                        if not created_at:
                            created_at = im.getexif().get(306)
                        if created_at:
                            new_filename = (dt.datetime.strptime(created_at, "%Y:%m:%d %H:%M:%S"))
                            if not os.path.exists(new_filename.strftime("%Y-%m-%d %H.%M.%S.jpg")):
                                os.rename(image, new_filename.strftime("%Y-%m-%d %H.%M.%S.jpg"))
                            else:
                                for i in range(200):
                                    if not os.path.exists("{}-{}.jpg".format(new_filename.strftime("%Y-%m-%d %H.%M.%S"), i)):
                                        os.rename(image, "{}-{}.jpg".format(new_filename.strftime("%Y-%m-%d %H.%M.%S"), i))
                                        break
                        else:
                            stat_info = os.stat(image)
                            print(str(stat_info))
                            new_filename = dt.datetime.fromtimestamp(stat_info.st_mtime)
                            if not os.path.exists(new_filename.strftime("%Y-%m-%d %H.%M.%S.jpg")):
                                os.rename(image, new_filename.strftime("%Y-%m-%d %H.%M.%S.jpg"))
                            else:
                                for i in range(200):
                                    if not os.path.exists("{}-{}.jpg".format(new_filename.strftime("%Y-%m-%d %H.%M.%S"), i)):
                                        os.rename(image, "{}-{}.jpg".format(new_filename.strftime("%Y-%m-%d %H.%M.%S"), i))
                                        break

                    elif 'mp4' in image.lower():
                        mp4_info = ffmpeg.probe(image)
                        print(mp4_info['format']['tags'])
                        created_at = parser.parse(mp4_info['streams'][0]['tags']['creation_time'])
                        if not os.path.exists(created_at.strftime("%Y-%m-%d %H.%M.%S.mp4")):
                            os.rename(image, created_at.strftime("%Y-%m-%d %H.%M.%S.mp4"))
                except Exception as e:
                    print("error ", str(e))

if __name__ == "__main__":
    get_date_taken()
