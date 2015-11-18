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
	if (argc==1) exit(0,"USAGE: pike [-c:s] %s *.srt\nor some subset of srt files\n",argv[0]);
	string copy="-c";
	array(string) dir=utf8_to_string(allfiles(audio_sources)[*]);
	nextarg: foreach (argv[1..],string fn)
	{
		if (has_prefix(fn,"-c")) {copy=fn; continue;} //Change the copy effect used by passing -c:s or similar.
		sscanf(lower_case(utf8_to_string(fn)),"%s - %s.srt",string lang,string tit);
		foreach (dir,string f) if (has_value(lower_case(f),lang))
		{
			write("Creating: %O\n",lang);
			string out=fn-".srt"+".mkv";
			Process.create_process(({"avconv",
				//"-itsoffset","0.250",
				"-i","LetItGo.mkv",
				"-i",string_to_utf8(f),
				"-i",fn,
				"-map","0:v","-map","1:a:0","-map","2:s",
				copy,"copy",fn-".srt"+".mkv"
			}))->wait();
			//Flag the subtitles track as active-by-default
			//Requires mkvtoolnix package.
			//TODO: Is there a way to do this inside avconv?
			catch {Process.create_process(({"mkvpropedit",out,
				"--edit","track:s1","--set","flag-default=1"}))->wait();
			};
			continue nextarg;
		}
		//TODO: Possibly search for the title too - though this can have false positives
		write("Not found: %s\n",fn);
	}
}

