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

int main()
{
	array(string) dir=glob("*.mp3",utf8_to_string((allfiles("Audio/CD1")+allfiles("Audio/CD2"))[*]));
	dir-=glob("*End Credit Version*",dir); //Ignore the Demi versions
	foreach (get_dir(),string fn) if (has_suffix(fn,".srt"))
	{
		sscanf(lower_case(utf8_to_string(fn)),"%s - %s.srt",string lang,string tit);
		foreach (dir,string f) if (has_value(lower_case(f),lang))
		{
			//Remove just the first matching entry - not any others.
			//There normally won't be... I think. But just in case.
			dir-=({f});
			break;
		}
	}
	dir=string_to_utf8(dir[*]);
	write("%{%s\n%}",dir);
	exece("/usr/bin/vlc",dir);
}

