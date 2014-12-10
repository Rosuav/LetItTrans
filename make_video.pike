constant audio_sources="Audio"; //Point this to the directory where you have the audio files eg CD1, CD2 - will search it recursively for files

array(string) allfiles(string path)
{
	array(string) files=get_dir(path);
	if (!files) return ({ });
	array(string) ret=({ });
	foreach (sort(files),string f)
	{
		f=combine_path(path,f);
		if (file_stat(f)->isdir) ret+=allfiles(f);
		else ret+=({f});
	}
	return ret;
}

int main(int argc,array(string) argv)
{
	if (argc==1) exit(0,"USAGE: pike %s *.srt\nor some subset of srt files\n",argv[0]);
	array(string) dir=utf8_to_string(allfiles(audio_sources)[*]);
	nextarg: foreach (argv[1..],string fn)
	{
		sscanf(lower_case(utf8_to_string(fn)),"%s - %s.srt",string lang,string tit);
		foreach (dir,string f) if (has_value(lower_case(f),lang))
		{
			write("Creating: %O\n",lang);
			Process.create_process(({"avconv",
				"-i","LetItGo.mkv",
				"-i",string_to_utf8(f),
				"-i",fn,
				"-map","0:v","-map","1:a:0","-map","2:s",
				"-c","copy",fn-".srt"+".mkv"
			}))->wait();
			continue nextarg;
		}
		//TODO: Possibly search for the title too - though this can have false positives
		write("Not found: %s\n",fn);
	}
}

