# this is a script to add arbitrary amounts of green to a texture

import sys
import os
import numpy as np
from PIL import Image
import OpenEXR
import Imath


def injectCol(img, col):
    # img is a PIL image
    # col is a 3-tuple of RGB values
    img = np.array(img)
    img = img.astype(np.float32)
    img += np.array(col)
    img = np.clip(img, 0, 255)
    img = img.astype(np.uint8)
    return Image.fromarray(img)

def load_exr_as_pil(path):
    # Open the EXR file
    exr_file = OpenEXR.InputFile(path)

    # Get the size of the image
    dw = exr_file.header()['dataWindow']
    size = (dw.max.x - dw.min.x + 1, dw.max.y - dw.min.y + 1)

    # Read the three color channels as 32-bit floats
    FLOAT = Imath.PixelType(Imath.PixelType.FLOAT)
    redstr = exr_file.channel('R', FLOAT)
    greenstr = exr_file.channel('G', FLOAT)
    bluestr = exr_file.channel('B', FLOAT)

    # Convert the strings to 1D numpy arrays
    red = np.fromstring(redstr, dtype = np.float32)
    green = np.fromstring(greenstr, dtype = np.float32)
    blue = np.fromstring(bluestr, dtype = np.float32)

    # Reshape the arrays to 2D
    red.shape = (size[1], size[0]) # Numpy arrays are (row, col)
    green.shape = (size[1], size[0])
    blue.shape = (size[1], size[0])

    # Stack the channels together
    image = np.dstack((red, green, blue))

    return image

def gamma_correction(image, gamma):
    image = np.power(image/255, 1/gamma) * 255
    image = image.astype(np.uint8)
    image = np.clip(image, 0, 255)

    return image

#this is from James, cite him 
def linear_to_sRGB(color, use_quantile=False, q=None, clamp=True):
    """Convert linear RGB to sRGB.
    Args:
        color: [..., 3]
        use_quantile: Whether to use the 98th quantile to normalise the color values.
        q: Optional precomputed quantile value.
        clamp: Whether to clamp the values to [0, 1].
    Returns:
        color: [..., 3]
    """
    if use_quantile or q is not None:
        if q is None:
            q = np.quantile(color.flatten(), 0.98)
        color = color / q

    color = np.where(
        color <= 0.0031308,
        12.92 * color,
        1.055 * np.power(np.abs(color), 1 / 2.4) - 0.055,
    )
    if clamp:
        color = np.clip(color, 0.0, 1.0)

    color = np.clip(color, 0, 1)

    color = (color * 255).astype(np.uint8)
    color = np.clip(color, 0, 255)

    color = Image.fromarray(color)

    return color

#change current path
rootPath = "C:\\Users\\tw1700\\OneDrive - University of York\\Documents\\PhDCore\\pbrt-v2-skin\\"

#load im
imPath = "results\\experiments\\MultipleScalings\\normTex\\permutedTextures\\S000PermID1_ScaleMag3normTexISONorm_Multiplicative.exr"
im = load_exr_as_pil(rootPath + imPath)


im = linear_to_sRGB(im, use_quantile=True) #tone map
#show unedited im 
im.show()

#inject color
col = (0, 50, 0) #green
im1 = injectCol(im, col)

#disp
im1.show()

#inject red
col = (50, 0, 0) #red
im2 = injectCol(im, col)
im2.show()

#inject blue
col = (0, 0, 50) #blue
im3 = injectCol(im, col)
im3.show()


