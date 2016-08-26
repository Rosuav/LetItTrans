//"What one man can invent another can discover," said Holmes, regarding the Dancing Men.
string gtrans_hash(string input)
{
	mixed d = ({408934, 2955748344}); //Some sort of magic key.
	mixed a = d[0];
	mixed e = (array)string_to_utf8(input);
	foreach (e, int f)
	{
		a += f;
		//"+-a"
		a = (a + (a << 10)) & 4294967295;
		//"^+6"
		a = a ^ ((a&4294967295) >> 6);
	}
	//"+-3"
	a = (a + (a<<3)) & 4294967295;
	//"^+b"
	a = a ^ ((a&4294967295) >> 11);
	//"+-f";
	a = (a + (a<<15)) & 4294967295;
	a ^= (int)d[1];
	if (a < 0) a = (a & 2147483647) + 2147483648;
	a %= 1000000;
	return sprintf("%d.%d", a, a^d[0]);
}

int main(int argc,array(string) argv)
{
	foreach (argv[1..],string fn)
	{
		string language=(["Swedish":"sv","Portuguese":"pt","Czech":"cs"])[(fn/" ")[0]] || lower_case(fn[..1]); //Hack: If the language code is the first two letters, figure it out without the mapping.
		int has_translit=(<"ru">)[language]; //Those which use transliterations have extra text lines.
		//language="auto"; //Or use "Detect Language" mode. Probably not a good idea for short clips.
		array(array(string)) input=(String.trim_all_whites(utf8_to_string(Stdio.read_file(fn)))/"\n\n")[*]/"\n";
		int engonly=0,trans=0,gtrans=0;
		int changed=0,ital=0;
		int notrans=0; signal(2,lambda() {notrans=1;});
		int tot_english,tot_other,tot_trans;
		foreach (input;int i;array(string) para) switch (sizeof(para)-has_translit)
		{
			case 1: //English text only, when we're looking for a transliteration.
			case 2: engonly++; break; //English text only - nothing to do (but keep stats)
			case 3: //This is the interesting case - we have three lines: the header, the English, and the other.
			{
				if (notrans) break; //Hit Ctrl-C to abort translation (but keep checking for italicization, just in case)
				object result=Protocols.HTTP.get_url(
					//Base URL - I have no idea what all this means, but it does seem to work
					"http://translate.google.com/translate_a/single?client=t&sl="+language+"&tl=en&hl=en&dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&ie=UTF-8&oe=UTF-8&pc=1&otf=1&srcrom=1&ssel=0&tsel=0&kc=1",
					//Text that we want to translate (gets properly encoded), and its error-detection hash
					(["q":para[2], "tk": gtrans_hash(para[2])]),
					//And set a UA.
					(["User-Agent":"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36"])
				);
				if (result->status != 200) return 1;
				//Hacky means of parsing it out. VERY hacky.
				sscanf(utf8_to_string(result->data()),"[[[%s]]",string parseme); if (!parseme) parseme="";
				//If you now examine "[["+parseme+"]]", it should be a JSON array of two-element arrays
				//where the first is the English backtranslation and the second is the original text,
				//for each section. We just want the first part. Note that in some cases, the first part
				//does not begin with a quote. "%O,%*O" misparses this (skipping over empty commas), so
				//we explicitly filter down to the ones that start with quotes.
				array parts=array_sscanf(filter(parseme/"],[",has_prefix,"\"")[*],"%O,%*O")[*][0];
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
				if (has_prefix(para[-1],"[") || has_prefix(para[-1],"<i>[")) gtrans++; else trans++; //Has subs and trans; keep stats separately based on GTrans or not
				//Check to see if the English is italicized. If it is, make sure the other lines are too.
				if (has_prefix(para[1],"<i>"))
				{
					for (int i=2;i<sizeof(para);++i) if (!has_prefix(para[i],"<i>")) {para[i]="<i>"+para[i]+"</i>"; ital++;}
				}
				tot_english += sizeof(para[1]-"<i>"-"</i>");
				tot_other += sizeof(para[-2]-"<i>"-"</i>");
				tot_trans += sizeof(para[-1]-"<i>"-"</i>"-"["-"]");
				break;
			}
			default: write("Unknown para len %d on para %d\n",sizeof(para),i); //Probably broken input
		}
		write("English-only: %d\nWith subs and GTrans: %d\nWith subs and proper trans: %d\n",engonly,gtrans,trans);
		if (tot_english) write("Total English characters in translated sections: %d\nTranslated characters: %d [%d%%]\nTranslation back: %d [%d%% of above, %d%% of English]\n",tot_english,
			tot_other,100*tot_other/tot_english,
			tot_trans,100*tot_trans/tot_other,100*tot_trans/tot_english,
		);
		if (changed || ital)
		{
			if (changed) write("%d new GTranslations made.\n",changed);
			if (ital) write("%d italicizations made.\n",ital);
			Stdio.write_file(fn,string_to_utf8(input[*]*"\n"*"\n\n"+"\n"));
		}
	}
}
