int main(int argc,array(string) argv)
{
	foreach (argv[1..],string fn)
	{
		array para=Stdio.read_file(fn)/"\n\n";
		foreach (para;int i;string p) if (has_value(p,"<i>"))
		{
			sscanf(p,"%s\n%s",string hdr,string body);
			para[i]=hdr+"\n{\\an8}"+(body-"<i>"-"</i>");
		}
		Stdio.write_file(fn,para*"\n\n");
	}
}
