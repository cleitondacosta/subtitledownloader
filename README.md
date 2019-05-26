# Subtitle Downloader

### Installation

```
git clone https://github.com/cleitondacosta/subtitledownloader.git
cd subtitledownloader
chmod +x subtitle_downloader.rb
```

You can move the `subtitle_downloader.rb` to some directory that is in
your PATH.

### USAGE

```
./subtitle_downloader.rb /path/to/movie LANGUAGE
```

LANGUAGE is a short to the desired subtitle language to download.
Supported languages:

| Short  | Language         |
| ------ | ---------------- |
| pt     | Portuguese (BR)  |
| en     | English          |
| fr     | French           |
| es     | Spanish          |

### Example

```
./subtitle_downloader.rb ~/movies/legally-obtained-movie.mp4 pt
```

The above command will download a brazilian portuguese subtitle for
`~/movies/legally-obtained-movie.mp4`. If the subtitle is found, a file
`~/movies/legally-obtained-movie.srt` will be created.

### Warning

This command depends on subdb's server availability.
