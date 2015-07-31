int main(int argc,array(string) argv)
{
	foreach (argv[1..],string fn)
	{
		string language=(["Swedish":"sv"])[(fn/" ")[0]] || lower_case(fn[..1]); //Hack: If the language code is the first two letters, figure it out without the mapping.
		//language="auto"; //Or use "Detect Language" mode. Probably not a good idea for short clips.
		array(array(string)) input=(String.trim_all_whites(utf8_to_string(Stdio.read_file(fn)))/"\n\n")[*]/"\n";
		int engonly=0,trans=0,gtrans=0;
		int changed=0,ital=0;
		foreach (input;int i;array(string) para) switch (sizeof(para))
		{
			case 2: engonly++; break; //English text only - nothing to do (but keep stats)
			case 3: //This is the interesting case - we have three lines: the header, the English, and the other.
			{
				string result=Protocols.HTTP.get_url_data(
					//Base URL - I have no idea what all this means, but it does seem to work
					"http://translate.google.com/translate_a/single?client=t&sl="+language+"&tl=en&hl=en&dt=bd&dt=ex&dt=ld&dt=md&dt=qc&dt=rw&dt=rm&dt=ss&dt=t&dt=at&ie=UTF-8&oe=UTF-8&ssel=3&tsel=3&otf=1&kc=11&tk=519600|625420",
					//Text that we want to translate (gets properly encoded)
					(["q":para[2]]),
					//And set a UA.
					(["User-Agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36"])
				);
				//Hacky means of parsing it out. VERY hacky.
				sscanf(utf8_to_string(result),"[[[%s]]",string parseme); if (!parseme) parseme="";
				//If you now examine "[["+parseme+"]]", it should be a JSON array of two-element arrays
				//where the first is the English backtranslation and the second is the original text,
				//for each section. We just want the first part.
				array parts=array_sscanf((parseme/"],[")[*],"%O,%*O")[*][0];
				//GTrans sometimes returns final punctuation after a space. Trim out the space.
				mapping punct=([]); foreach (",.!:?'\""/1,string ch) punct[" "+ch]=ch;
				parts=replace(parts[*],punct);
				foreach (parts;int i;string p) if (sizeof(p)>2 && p[-2]==' ' && (<',','.','!',':',')'>)[p[-1]]) parts[i]=p[..<2]+p[<0..];
				string trans=replace(parts*"",(["( ":"("," )":")"])); //Clean up spaces inside parens
				input[i]+=({"["+trans+"]"}); //Note that this is done even if the translation fails, and will prevent it being redone.
				write("Translated:\n%{%s\n%}\n",string_to_utf8(input[i][*]));
				sleep(1); //Voluntarily rate-limit our usage
				changed++;
				break;
			}
			case 4:
			{
				if (para[3][0]=='[') gtrans++; else trans++; //Has subs and trans; keep stats separately based on GTrans or not
				//Check to see if the English is italicized. If it is, make sure the other lines are too.
				if (has_prefix(para[1],"<i>"))
				{
					for (int i=2;i<4;++i) if (!has_prefix(para[i],"<i>")) {para[i]="<i>"+para[i]+"</i>"; ital++;}
				}
				break;
			}
			default: write("Unknown para len %d on para %d\n",sizeof(para),i); //Probably broken input
		}
		write("English-only: %d\nWith subs and GTrans: %d\nWith subs and proper trans: %d\n",engonly,gtrans,trans);
		if (changed || ital)
		{
			if (changed) write("%d new GTranslations made.\n",changed);
			if (ital) write("%d italicizations made.\n",ital);
			Stdio.write_file(fn,string_to_utf8(input[*]*"\n"*"\n\n"+"\n"));
		}
	}
}
