/**
    @name: PendulumClock
    @description:

    To get good rotation, plase apply scale and rotaion in Blender,
        and make the back of object should be directed to x (west)
        ask teacher Modee Parlez

    Name second object/prim as "Seconds" case sensitive
    Name minutes object/prim as "Minutes" case sensitive
    Name hours object/prim as "Hours" case sensitive
    Name pendulum object/prim as "Pendulum" case sensitive


    @author: Lilim
    @updated: "2022-07-15 02:44:39"
    @localfile: ?defaultpath\PendulumClock\?@name.lsl
    @version: 1
    @revision: 12

    @ref:
        http://wiki.secondlife.com/wiki/LlGetGMTclock
        http://wiki.secondlife.com/wiki/PRIM_ROTATION

    @notice:
        Link number is based on 1
*/

/***********************
    Setting
      You can change it
************************/

float gRefreshRate = 1;
//* GMT Timezone
integer gLocalOffset = 0;
//integer gLocalOffset = -8; //California
//* 0 Simple
//* 1 Steps
//* 2 Omega
integer gPendulumType  = 2; //* use omega rotate
integer gPendulumSteps = 1; //* only type 2
float   gPendulumAngle = 5;
float   gPendulumGain = 3;

/***********************
    Gloabl variables
      Do not change it
************************/

//* yes it is a float, because we need it for analog clock hands
float gSeconds = 0;
float gMinutes = 0;
float gHours   = 0;

/**
    We need save old value for checking if changed we will rotate it, nop, we do not rotate it every second, for less lag server
*/
float gOldSeconds   = 0;
float gOldMinutes   = 0;
float gOldHours     = 0;

//* Link numbers
integer gSecondsHand = 0;
integer gMinutesHand = 0;
integer gHoursHand   = 0;
integer gPendulumHand = 0;

integer gPendulumState = 1;
integer gPendulumDirection = 1; //* const

//* case sensitive
integer getPrimNumber(string name)
{
    integer c = llGetNumberOfPrims();
    integer i = 1; //based on 1
    while(i <= c)
    {
        if (llGetLinkName(i) == name) // llGetLinkName based on 1
        {
            //* better to reset position and rotate
            llSetLinkPrimitiveParams(i, [PRIM_ROTATION, ZERO_ROTATION]);
            llSetLinkPrimitiveParams(i, [PRIM_OMEGA, <0, 0, 0>, 0, 0 ]);
            return i;
        }
        i++;
    }
    llOwnerSay("Could not find " + name);
    return -1;
}

calcTime(){
    //* get the time as second from the midnight, then devided it to 60 to convert it to minutes from midnight
    float lTime = ((integer)llGetGMTclock() + (gLocalOffset * 3600));
    gSeconds = (integer) lTime % 60;
    lTime = (integer) lTime / 60;
    //*
    gHours = lTime / 60; //* we need it float
    //* get the rest (mod) of minutes
    gMinutes = (integer) lTime % 60;
    if (gHours > 12){
        gHours = gHours - 12;
    }
}

rotate(integer linkNumber, vector v){
    //llSetRot(llEuler2Rot(v * DEG_TO_RAD));
    llSetLinkPrimitiveParams(linkNumber, [PRIM_ROT_LOCAL, llEuler2Rot(v * DEG_TO_RAD)]);
}

rotateHands(){
    calcTime();
    //llSay(0, "The time now " + (string) gHours + ":" + (string) gMinutes);

    if ((gSecondsHand > 0) && (gOldSeconds != gSeconds)) {
        rotate(gSecondsHand, <gSeconds * 6, 0, 0>); //* 60 is 360 degree / 12 minutes
        gOldSeconds = gSeconds;
    }

    if ((gMinutesHand) > 0 && (gOldMinutes != gMinutes)) {
        rotate(gMinutesHand, <gMinutes * 6, 0, 0>); //* 6 is 360 degree / 60 minutes
        gOldMinutes = gMinutes;
    }

    if ((gHoursHand > 0) && (gOldHours != gHours)) {
        rotate(gHoursHand, <gHours * 30, 0, 0>); //* 30 is 360 degree / 12 hours
        gOldHours = gHours;
    }

    if (gPendulumHand > 0)
    {
        if (gPendulumType == 2)
        {
            gPendulumState = -gPendulumState;

            /**
                We have problem in omega rotate, it is done in the viewer, more smooth yes, but not reset to the right position,
                so if viewer of server lag, it took long time to take another direction, so it take more tilting and unstable,
                for that i reset the rotate by angle (not zero, zero not effects)
            */
            llSetLinkPrimitiveParams(gPendulumHand, [PRIM_ROT_LOCAL, llEuler2Rot(<-gPendulumState * gPendulumAngle, 0, 0> * DEG_TO_RAD)]);
            //llSetLinkPrimitiveParams(gPendulumHand, [PRIM_OMEGA, <gPendulumState, 0, 0>, gPendulumAngle * DEG_TO_RAD, 1]);
            llSetLinkPrimitiveParams(gPendulumHand, [PRIM_OMEGA, <gPendulumState, 0, 0>, gPendulumAngle  * gPendulumGain * DEG_TO_RAD, 1]);
        }
        else if (gPendulumType == 1) //* using normal rotate
        {
            gPendulumState = gPendulumState + gPendulumDirection;
            if ((gPendulumState >= gPendulumSteps)) {
                gPendulumDirection = -1;
            } else if ((gPendulumState <= -gPendulumSteps)) {
                gPendulumDirection = 1;
            }
            rotate(gPendulumHand,  <gPendulumState * gPendulumAngle, 0, 0>);
        }
        else
        {
            gPendulumState = -gPendulumState;
            llSetLinkPrimitiveParams(gPendulumHand, [PRIM_ROTATION, llEuler2Rot(<-gPendulumState * gPendulumAngle, 0, 0> * DEG_TO_RAD)]);
        }
    }
}

integer dialog_channel;
integer dialog_listen_id; //* dynamicly generated menu channel

showDialog(key toucher_id) {
    llDialog(toucher_id, "Clock Setting", ["Offset+", "Offset-", "Reset"], dialog_channel);
    llListenRemove(dialog_listen_id);
    dialog_listen_id = llListen(dialog_channel, "", toucher_id, "");
}

default{
    state_entry()
    {
        dialog_channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -7, -1) );

        gSecondsHand = getPrimNumber("Seconds");
        gMinutesHand = getPrimNumber("Minutes");
        gHoursHand = getPrimNumber("Hours");
        gPendulumHand = getPrimNumber("Pendulum");

        llSetTimerEvent(gRefreshRate); //seconds
        rotateHands();
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }

    touch_start(integer num_detected)
    {
        if (llGetOwner() == llDetectedKey(0))
            showDialog(llDetectedKey(0));
    }

    listen (integer channel, string name, key id, string message)
    {
        if (channel == dialog_channel)
        {
            llListenRemove(dialog_listen_id);
            if (message == "Offset+") {
                gLocalOffset++;
                llOwnerSay("Offset now is: " + (string)gLocalOffset);
            }
            else if (message == "Offset-") {
                gLocalOffset--;
                llOwnerSay("Offset now is: " + (string)gLocalOffset);
            }
            else if (message == "Reset") {

            }
        }
    }

    timer(){
        rotateHands();
    }
}
