# Creating Maps

To download an offline map, we will use [proto maps](https://docs.protomaps.com/guide/getting-started). 

After downloading protomaps, you will then need a bounding box to download. This website allows you to get bounding boxes. This is the bounding box for [Hoboken](http://bboxfinder.com/#40.703152,-74.081470,40.777667,-73.997370).

Using the Hoboken bounding box as an example, run the following command:

```bash 
pmtiles extract https://build.protomaps.com/20260224.pmtiles hoboken_small.pmtiles --bbox=-74.081470,40.703152,-73.997370,40.777667
```

> [!NOTE] 
> Try to keep the final file size under 80 MB, or else you may run into issues pushing into GitHub, and will need to use Git LFS.

