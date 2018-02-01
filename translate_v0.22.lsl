// Open Translate v.0.22 - Jan 27 2018
// by Cuga Rajal and Xiija Anzu
//
// Put this script in a HUD and wear it. Click the HUD to open the configuration dialog and set language choices.
// This translator assumes the HUD owner speaks a different language than the local chat.
// Get the latest version at https://github.com/cuga-rajal/translator
// Compatible with Opensim and Second Life. See the Readme file for more details.
// When the HUD owner types in local chat, it will be translated from the source language to the target language.
// The HUD owner's translated phrase will then be printed to local chat for all to see.
// When other people speak in local chat, their phrases are translated from the target language to source language.
// Others' translated phrases will then be printed only to the HUD owner's local chat.
// Translated phrases are printed to local chat only if they are different from the original phrase.
// There is a limit of 16kb per translation. Anything exceeding that is truncated.

key  XMLRequest;
string sourceLang = "es"; // language of the HUD owner, can be changed from setup dialog
string targetLang = "en"; // common language in local chat, can be changed from setup dialog
string msg = "a bunny";
string url2;
integer listenHandle;
string name;
integer chan;
list gLstMnu;
string txt;
key id;
integer handle;
integer ttlPG;
integer currPG = 0;
integer i;
string langselect = "";
integer setup = 0;
 

list langs = 
[
"Arabic",       "ar", 
"Chinese",      "zh-TW",
"Dutch",        "nl",
"English",      "en",
"French",       "fr",
"German",       "de",
"Italian",      "it",
"Japanese",     "ja",
"Korean",       "ko",
"Portuguese",   "pt",
"Russian",      "ru",
"Spanish",      "es"    
];

list uDlgBtnLst( integer vIdxPag ) {
    gLstMnu = llList2ListStrided(langs, 0, -1, 2);;
    integer vIntTtl = -~((~(integer)([] != gLstMnu)) / 9);      //-- Total possible pages
    integer vIdxBgn = vIdxPag * 9;
    string backbut;
    if(vIdxPag==0) { backbut=" "; } else { backbut = "<<"; }
    string fwdbut;
    if(vIdxPag==vIntTtl) { fwdbut=" "; } else { fwdbut = ">>"; }
    list vLstRtn = llList2List( gLstMnu, vIdxBgn, vIdxBgn + 8 ) + backbut + "Close" + fwdbut;
    return //-- fix the order for [L2R,T2B] and send it out
      llList2List( vLstRtn, -3, -1 ) + llList2List( vLstRtn, -6, -4 ) +
      llList2List( vLstRtn, -9, -7 ) + llList2List( vLstRtn, -12, -10 );
}    

poll() {
     XMLRequest =
     llHTTPRequest( url2 , [
     //HTTP_USER_AGENT, "XML-Getter/1.0 (Mozilla Compatible)", // HTTP_USER_AGENT not supported in Opensim, uncomment for SL
     HTTP_METHOD, "GET", 
     HTTP_MIMETYPE, "text/html;charset-utf8", 
     HTTP_BODY_MAXLENGTH,16384,
     HTTP_PRAGMA_NO_CACHE,TRUE], "");   
}

default {

    state_entry() {
        chan = 0x80000000 | (integer)("0x"+(string)llGetOwner());    // unique channel based on owners UUID   
        listenHandle = llListen(0, "","", "");
        name = llGetDisplayName(llGetOwner());
        llOwnerSay("Resetting...");
    }
    
    touch_start(integer total_number) {   
        id = llDetectedKey(0);
        txt = "Current settings:\n HUD owner language (source): " + llList2String(langs,llListFindList(langs,(list)sourceLang)-1) + 
          "\n Local chat language (target): " + llList2String(langs,llListFindList(langs,(list)targetLang)-1) +
          "\n\nChange:";
        llDialog(id, txt, ["Source","Target","Close"], chan );
        handle = llListen(chan,"","","");
        llListenControl(handle, TRUE); 
        llSetTimerEvent(20);
    }   

    http_response(key k,integer status, list meta, string body) { 
        if(k ==  XMLRequest) {
            string returnstring = llUnescapeURL( body );
            string translatedmessage = "";
            list phraselist = llParseString2List(returnstring,[ "[", "]" ], [ "],[" ]);
            for(i=0; i<llGetListLength(phraselist); i++) {
                if(i %2==1) { jump next; } // Why this is required? Bug fix? 
                list thisphrase = llParseString2List(llList2String(phraselist,i),[ "\"" ], [ "\",\"" ]);
                translatedmessage += llList2String(thisphrase,0);
                @next;
            }
            if(msg == translatedmessage) { jump skipme; }
            if(llGetDisplayName(llGetOwner())==name) { llSay(0,name + ": "  + translatedmessage); }
            else { llOwnerSay(name + ": "  + translatedmessage); }
            @skipme;
        }
    }
    
    listen( integer vIntChn, string vStrNom, key vKeySpk, string vStrMsg ) {
        if (vIntChn == 0 ) {
            msg =  vStrMsg;   
            name = llGetDisplayName(vKeySpk);     
            url2 = "http://translate.googleapis.com/translate_a/single?client=gtx&sl=&dt=t&ie=UTF-8&oe=UTF-8";
            if(llGetDisplayName(llGetOwner())==name) { url2 += "&sl=" + sourceLang + "&tl=" + targetLang; }
            else { url2 += "&sl=" + targetLang + "&tl=" + sourceLang;  }
            url2 += "&q=" + llEscapeURL(msg);
            poll();
            return;
        }
        if(vStrMsg == "Source") {
            langselect = "source";
            txt = "Current settings:\n HUD owner language (source): " +
               llList2String(langs,llListFindList(langs,(list)sourceLang)-1) + 
               "\n Local chat language (target): " + llList2String(langs,llListFindList(langs,(list)targetLang)-1) +
               "\n\nPlease select source language:";
            llDialog(id, txt, uDlgBtnLst(currPG), chan );
            llSetTimerEvent(20); 
        } else if(vStrMsg == "Target") {
            langselect = "target";
            txt = "Current settings:\n HUD owner language (source): " +
               llList2String(langs,llListFindList(langs,(list)sourceLang)-1) + 
               "\n Local chat language (target): " + llList2String(langs,llListFindList(langs,(list)targetLang)-1) +
               "\n\nPlease select target language:";
            llDialog(id, txt, uDlgBtnLst(currPG), chan );
            llSetTimerEvent(20); 
        } else if(vStrMsg == ">>") {
            ++currPG;
            if(currPG > ttlPG) { currPG = 1;}
            llDialog(id, txt, uDlgBtnLst(currPG), chan );
            llSetTimerEvent(20); 
        } else if(vStrMsg == "<<") {
            --currPG;
            if(currPG < 1) { currPG = ttlPG;}
            llDialog(id, txt, uDlgBtnLst(currPG), chan );
            llSetTimerEvent(20); 
        } else if (vStrMsg == "Close") {
            llSetTimerEvent(0.5);
        } else if (vStrMsg == " ") {
            llDialog(id, txt, uDlgBtnLst(currPG), chan );
            llSetTimerEvent(20); 
        } else {
            if(langselect=="source") {
                sourceLang = llList2String(langs,llListFindList(langs,(list)vStrMsg)+1);
                llOwnerSay("Source language set to " + vStrMsg);
            } else if(langselect=="target") {    
                targetLang = llList2String(langs,llListFindList(langs,(list)vStrMsg)+1);
                llOwnerSay("Target language set to " + vStrMsg);
            }      
        }
    }
    
    timer() {
        llListenControl(handle, FALSE);
        llSetTimerEvent(0);
    }
    
    changed(integer change) {
        if (change & (CHANGED_REGION_START | CHANGED_OWNER | CHANGED_INVENTORY) ) {
            llResetScript();
        }
    }
    
    attach (key id) {
        if (id) {
            llResetScript();
        }
    }
}
