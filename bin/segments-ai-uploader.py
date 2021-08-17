import glob
import ntpath
from os.path import abspath
from segments import SegmentsClient


client = SegmentsClient('#unique_client_id')
dataset_name = '#dataset_name'
directory = "#path_to_directory_with_subtiles"
pathname = directory + "/**/*.png"

files = glob.glob(pathname, recursive=True)

for file in files:
    abs_file_path = abspath(file)
    with open(abs_file_path, "rb") as f:
        name = ntpath.basename(abspath(file))
        asset = client.upload_asset(f, filename=name)
        image_url = asset["url"]
        sample_name = name
        attributes = {
            "image": {"url": image_url}
        }
        result = client.add_sample(dataset_name, sample_name, attributes)


print("Files have been uploaded!")
