int main()
{
	//Start by enumerating characters used in English. This is mainly off the English subtitles file, but
	//with the entire upper-case alphabet added, since not all of them happen to come up in the small
	//corpus used here. Note that this set is assumed to be unaltered by NFC or NFD normalization.
	//(Lower case j and x seem to have missed representation too, so add them in.)
	multiset base=(multiset)Array.uniq((array)(utf8_to_string(Stdio.read_file("English - Let It Go.srt"))+"QWERTYUIOPASDFGHJKLZXCVBNMjx"));
	array files=glob("*.srt",get_dir());
	array nfc=allocate(sizeof(files)),nfd=allocate(sizeof(files));
	multiset all_nfc=(<>),all_nfd=(<>);
	foreach (files;int i;string fn)
	{
		string data=utf8_to_string(Stdio.read_file(fn));
		sscanf(fn,"%s - ",files[i]); //Get just the language, without the title, for brevity.
		multiset nfcchars=(multiset)Array.uniq((array)Unicode.normalize(data,"NFC"));
		multiset nfdchars=(multiset)Array.uniq((array)Unicode.normalize(data,"NFD"));
		nfc[i]=sizeof(nfcchars-base); nfd[i]=sizeof(nfdchars-base);
		all_nfc|=nfcchars; all_nfd|=nfdchars;
	}
	sort(nfc,nfd,files);
	int len=max(@sizeof(files[*]));
	write("%"+len+"s   NFC   NFD  Diff\n","Language");
	foreach (files;int i;string fn) write("%"+len+"s %5d %5d %5d\n",fn,nfc[i],nfd[i],nfc[i]-nfd[i]);
	write("%"+len+"s %5d %5d %5d\n","Combined",sizeof(all_nfc-base),sizeof(all_nfd-base),sizeof(all_nfc-base)-sizeof(all_nfd-base));
}

