module beangle.task;

import std.uuid;
import beangle.util;

import std.stdio;
import std.datetime;

string nextChannelId(string name){
  auto st  = Clock.currTime();
  return sha1UUID(name~st.toISOString()).toString();
}

unittest{
  writeln(nextChannelId("dd"));
}

int main(string[] args){
  if (args.length<2){
    import std.stdio;
    writeln("Usage: " ~ args[0] ~ " path/to/sas.xml");
    return -1;
  }

  import beangle.xml : readXml;
  auto xml = readXml(args[1]);

  import beangle.task.agent : startAgent;
  import beangle.task.server : startServer;
  import std.string: indexOf;
  if (xml.indexOf("port") > -1){
    return startServer(xml, args);
  }else {
    return startAgent(xml, args);
  }
}
