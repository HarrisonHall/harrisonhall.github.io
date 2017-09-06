var images = document.getElementById("images");
var character1 = document.getElementById("character1");
var character2 = document.getElementById("character2");
var text = document.getElementById("text");
var text2 = document.getElementById("text2");
var speech = document.getElementById("speech");
var textstyle = document.getElementById("text").style.fontFamily;
var buttonBox = document.getElementById("buttonBox");
//var input = document.getElementById('input');
var index;
var intObject;

var counter1 = 0;
var storyvar = 0;

//Defines how to change the first text
var changeText = function(words) {
  text.innerHTML = words;
};

var changeTextstyle = function(funk) {
  document.getElementById("text").style.font = funk;
};

var changeTextcolor = function(color) {
  document.getElementById("text").style.color = color;
};

//var changeItem = function(thingy) {
//  item.push(thingy);
//};

 //Defines how to change the second set of text
var changeText2 = function(words) {
  text2.innerHTML = words;
};

var changeTextstyle2 = function(funk2) {
  document.getElementById("text2").style.font = funk2;
};

var changeTextcolor2 = function(color) {
  document.getElementById("text2").style.color = color;
};

var buttonstyle = function(color) {
  document.getElementById("buttonBox").style.color = color;
};

//Defines how to change the dialogue 1




var changeImage = function(img0) {
  images.style.backgroundImage = "url(" + img0 + ")";
};

var changeCharacter1 = function(img1) {
  character1.style.backgroundImage = "url(" + img1 + ")";
};

var changeCharacter2 = function(img2) {
  character2.style.backgroundImage = "url(" + img2 + ")";
};

// background
var changeBackground = function(int) {
  document.body.id = "b"+int;
}

//Defines the button box
var changeButtons = function(buttonList) {
  buttonBox.innerHTML = "";
  for (var i = 0; i < buttonList.length; i++) {
    buttonBox.innerHTML += "<button onClick="+buttonList[i][1]+">" + buttonList[i][0] + "</button>";
  }
};

//Gives abilities to modify, leaving blank will eliminate the entry
var advanceTo = function(s) {
  changeImage(s.image)
  changeCharacter1(s.character1)
  changeCharacter2(s.character2)
  changeBackground(s.background)
  changeText(s.text)
  changeTextstyle(s.textstyle)
  changeTextcolor(s.textcolor)
  changeText2(s.text2)
  changeTextstyle2(s.textstyle2)
  changeTextcolor2(s.textcolor2)
//  changeTextspeed(s.textspeed)
  changeButtons(s.buttons)
  //changeItem(s.item)
  buttonstyle(s.buttonstyle)
};


//The acutal game
scenario = {}
var scenario = {
  prologueentry: {
    image: "",
    background: "forest.png",
    character1: "",
    character2: "",

    text: "The Trial",
    textcolor: "white",
    textstyle: "bold 50px Limelight,serif",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",

    buttons: [["Enter the Present", "advanceTo(scenario.prologue)"]]
},
  prologue: {
    image: "",
    character1: "",
    character2: "",
    background: "",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text: "What happens when an unstoppable force meets an immovable object? \
          This is called the irresistible force paradox. A classic paradox, this \
          question has left many questioning the results of the incompatible circumstances.\
          The Trial is a story about parodoxes. A story about choices. A story \
          about events one cannot understand, that just shouldn't occur.",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",
    buttons: [["CONTINUE", "advanceTo(scenario.begin)"]]
  },
  begin: {
    image: "",
    background: "",
    character1: "",
    character2: "",

    text: "",
    textcolor: "white",
    textstyle: "bold 50px Limelight,serif",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",

    buttons: [["Begin", "advanceTo(scenario.two)"]]
  },
  two: {
    image: "thunderbackgif.gif", //house
    character1: "billy.png",
    character2: "",
    background: "",
    text: "Brother! Wake up! What's going on?",
    textstyle: "22px 'Orbitron',sans-serif",
    textcolor: "#5533FF",
    text2: "",
    buttons: [["Yawn", "advanceTo(scenario.three)"],["'Why would I know?'", "advanceTo(scenario.three)"]]
  },
  three: {
    image: "camp.png",
    character1: "",
    character2: " ",
    text: "You quickly get up, realizing that the ground under you is rumbling. \
          A strange bliding light fills the midnight sky as you quickly pack up \
          the most important items you took along to your weekend camping trip. \
          You quickly realize that that would be impossible.",
    textcolor: "white",
    textstyle: "25px Ubuntu,sans",
    text2: "What do you take?",
    textcolor2: "white",
    textstyle2: "28px 'Press Start 2P',sans",
    buttons: [["Water bottles", "advanceTo(scenario.water)"],["Beef jerky","advanceTo(scenario.beef)"],["Flashlight", "advanceTo(scenario.flash)"],["Hatchet", "advanceTo(scenario.hatchet)"]]
  },
  water: {
    image: "bottle.png",
    background: "",
    character1: "",
    character2: "",
    text: "You grabbed the water bottles.",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",
    buttons: [["continue", "advanceTo(scenario.four)"]]
  },
   beef: {
    image: "jerky.png",
    background: "",
    character1: "",
    character2: "",
    text: "You grabbed the beef jerky.",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",
    buttons: [["continue", "advanceTo(scenario.four)"]]
},
  flash: {
    image: "light.png",
    background: "",
    character1: "",
    character2: "",
    text: "You grabbed the flashlight.",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",
    buttons: [["continue", "advanceTo(scenario.four)"]]
  },

  hatchet: {
    text: "You grabbed the hatchet.",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text2: "",
    image: "hatchet.png",
    buttons: [["continue", "advanceTo(scenario.four)"]]
  },

  four: {
      image: "",
      background: "",
      character1: "",
      character2: "",
      text: "You quickly race to your modest house with your brother in front. \
      You pass the all-familiar sign, 'Welcome to Nubatormenta.' \
      The sky continues to darken as the light begins to gain a faint purple tint; \
      the whirring of a foreign engine begins to fill the air as you approach the house.",
      textcolor: "white",
      textstyle: "25px Ubuntu,serif",
      text2: "A dark figure emerges.",
      textcolor2: "white",
      textstyle2: "25px Ubuntu,sans",
      buttons: [["continue", "advanceTo(scenario.five)"]]
  },

  five: {
    image: "",
    text: "'Schroder!'",
    textcolor: "#8a0707",
    textstyle: "27px 'Julius Sans One',sans",
    text2: "An ominous voice calls.",
    textcolor2: "white",
    textstyle2: "25px Ubuntu,sans",
    buttons: [["Continue running", "advanceTo(scenario.six)"],["Confront the figure", "advanceTo(scenario.maelstrom)"]]
  },

  six: {
    image: "",
    text: "You reach the city as a loud BOOM echoes from the sky.",
    textcolor: "white",
    textstyle: "25px Ubuntu,sans",
    text2: "",
    buttons: [["The PRESENT TRIAL", "advanceTo(scenario.trial1)"]]
  },

  maelstrom: {
    image: "",
    character1: "malestorm1.jpg",
    text: "You hear 'Schroder' being called again. This time, the voice is clearer: \
    a powerful, soft, yet familiar voice.",
    textcolor: "white",
    textstyle: "25px Ubuntu,sans-serif",
    text2: "Listen! Those who care about you the most will become invaluable!",
    textcolor2: "#8a0707",
    textstyle2: "22px 'Julius Sans One',sans",
    buttons: [["...", "advanceTo(scenario.maelstrom2)"]]
  },

  maelstrom2: {
    image: "",
    character1: "malestorm1.jpg",
    text: "You falter in your approach.",
    textcolor: "white",
    textstyle: "25px Ubuntu, sans-serif",
    text2: "Save the ones you love!",
    textcolor2: "#8a0707",
    textstyle2: "25px 'Julius Sans One',sans",
    buttons: [["...", "advanceTo(scenario.maelstrom3)"]]
  },
  maelstrom3: {
    image: "",
    character1: "",
    text: "You charge at the figure and lunge forward. You collide \
    into the cloak, but there is nothing there; you fall flat on your \
    face. Picking yourself up, you grab the cloak and run across the \
    gravel into the saftey of your house..",
    textcolor: "white",
    textstyle: "25px Ubuntu, sans-serif",
    text2: "",
    textcolor2: "#8a0707",
    textstyle2: "25px 'Julius Sans One',sans",
    buttons: [["continue", "advanceTo(scenario.six)"]]
  },

  trial1: {
    image: "hourse.png",
    background: "",
    character1: "",
    character2: "",
    text: "As soon as you enter the doorway, you see Billy running franctically \
    around the house.",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text2: "Mom isn't here!",
    textcolor2: "#5533ff",
    textstyle2: "22px Orbitron,sans",
    buttons: [["Help Billy Search the house.", "advanceTo(scenario.b4school)"],["Grab Billy and find Mom.", "advanceTo(scenario.b4school)"]]
  },
  b4school: {
    image: "",
    background: "",
    character1: "",
    character2: "",
    text: "You quickly search your home, but ultimately decide to go the the safest \
    place in town, the school.",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text2: "",
    textcolor2: "#5533FF",
    textstyle2: "40px Orbitron,sans",
    buttons: [["Continue", "advanceTo(scenario.schoolfront)"]]
  },
  schoolfront: { // See Jarrett
    image: "school.png",
    background: "",
    character1: "",
    character2: "",
    text: "As you reach Hill Valley Middle School, you see floodlights being set \
    up by a few members of the town. As you reach the school, you manage \
    to make out the face of your coworker.",
    textcolor: "white",
    textstyle: "25px Ubuntu,serif",
    text2: "",
    textcolor2: "",
    textstyle2: "",
    buttons: [["'Jarrett, what's going on here?'", "advanceTo(scenario.jarrett1)"],["'Jarrett, what are you doing?'","advanceTo(scenario.jarrett1)"]]
},
jarrett1: { // Talking with Jarret
  image: "",
  background: "",
  character1: "",
  character2: "",
  textcolor: "#cd7f32",
  textstyle: "20px Jockey One,serif",
  text: "Hey, the sheriff told us to set these up. I dunno know why, but he \
  seemed a little pale in the face when he told us.",
  text2: "",
  textcolor2: "",
  textstyle2: "",
  buttons: [["Hmph", "advanceTo(scenario.jarrett2)"],["'Really?'", "advanceTo(scenario.jarrett2)"]]
},
  jarrett2: {
    image: "",
    character1: "",
    character2: "",
    background: "",
    textcolor: "#cd7f32",
    textstyle: "20px Jockey One,serif",
    text: "Yeah, it's definitely strange. Did you see that UFO?",
    text2: "",
    textcolor2: "",
    textstyle2: "",
    buttons: [["'UFOs don't exist, dude.'", "advanceTo(scenario.school1)"],["'Go get your eyes checked, man.'","advanceTo(scenario.school1)"]]
  },
  school1: { // Enter school
    image: "",
    character1: "",
    character2: "",
    background: "",
    text: "Your friend shrugged his shoulders as you walked into the school. \
    \
    As you walk through the entrance, you notice a few men keeping watch of \
    the doorway. There's a rotunda at the center of the school, usually a hub \
    for activity; you head that way.",
    textstyle: "25px Ubuntu,sans",
    textcolor: "white",
    text2: "",
    buttons: [["continue", "advanceTo(scenario.school2)"]]
  },
  school2: { // Choose where to go
    image: "hallway.png",
    character1: "",
    character2: "",
    text: "The hallways seemed all too familiar, as if it was just yesterday you \
    were taking 8th grade classes. There are muddy footprints all across \
    the tiles; students' paintings lie across the ground as if a tornado \
    had ripped through the quiet Hill Valley Middle.",
    textcolor: "white",
    textstyle: "25px Ubuntu,sans",
    text2: "Where do you go?",
    textcolor2: "white",
    textstyle2: "28px 'Press Start 2P',sans",
    buttons: [["The cafeteria", "advanceTo(scenario.cafe)"],["The nurse's office","advanceTo(scenario.nurse)"],["The restroom", "advanceTo(scenario.restroom)"]]
  },
  cafe: { // Cafeteria
    image: "cafe.png",
    background: "",
    character1: "",
    character2: "",
    text: "As you walked into the cafeteria, voices of all kinds could be heard, \
    but most strikingly, your mom's cries of despair.",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text2: "",
    textcolor2: "",
    textstyle2: "",
    buttons: [["next", "advanceTo(scenario.school3)"]]
},
 nurse: { // Nurse's office
    image: "",
    background: "",
    character1: "",
    character2: "",
    text: "You flick on the lights as you walk into the room where you had gone \
    to many times in middle school. You see nothing of importance.",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text2: "",
    textcolor2: "",
    textstyle2: "",
    buttons: [["Head back", "advanceTo(scenario.school2)"]]
},
restroom: { // Restroom
    image: "",
    background: "",
    character1: "",
    character2: "",
    text: "The lights automatically turn on as you walk into the boys' restroom. \
    There's one leaky faucet, but nothing else notable.",
    textcolor: "white",
    textstyle: "bold 25px Ubuntu,serif",
    text2: "",
    textcolor2: "",
    textstyle2: "",
    buttons: [["Head back", "advanceTo(scenario.school2)"]]
},
  school3: { // Mom is crying
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "I knew letting them go camping was a bad idea...",
       textcolor: "red",
       textstyle: "22px Amaranth,serif",
       text2: "Don't cry. It's okay. Your kids will be fine.",
       textcolor2: "white",
       textstyle2: "20px Amiri,sans",
       buttons: [["next", "advanceTo(scenario.school4)"]]
 },
  school4: { // Mom looks up
       image: "",
       background: "",
       character1: "billy.png",
       character2: "",
       text: "Mom?",
       textcolor: "#5533ff",
       textstyle: "22px Orbitron ,serif",
       text2: "Billy called as you see him run into the cafeteria. \
       You see your mom look up from her hands.",
       textcolor2: "white",
       textstyle2: "25px Ubuntu,sans",
       buttons: [["next", "advanceTo(scenario.school5)"]]
  },
  school5: { // Responding to mom
       image: "",
       background: "",
       character1: "mom.png",
       character2: "",
       text: "Billy! Where's your brother? Oh, here you kids are! \
       Don't leave my sight ever again!",
       textcolor: "red",
       textstyle: "22px Amaranth ,serif",
       text2: "You say...",
       textcolor2: "white",
       textstyle2: "28px 'Press Start 2P',sans",
       buttons: [["Sorry about that mom. Promise not to do it again.", "advanceTo(scenario.sorrymom1)"],["Nothing","advanceTo(scenario.school6)"]]
  },
  sorrymom1: { // First response responding to mom
       image: "",
       background: "",
       character1: "mom.png",
       character2: "",
       text: "It's okay, at least you both are safe from that UFO...",
       textcolor: "red",
       textstyle: "20px Amaranth ,serif",
       text2: "",
       textcolor2: "white",
       textstyle2: "20px 'Press Start 2P',sans",
       buttons: [["Those don't exist.", "advanceTo(scenario.sorrymom2)"],["...","advanceTo(scenario.sorrymom2)"]]
  },
  sorrymom2: { // Second response to mom
       image: "",
       background: "",
       character1: "mom.png",
       character2: "",
       text: "Well that's what the sheriff said... speaking of whom...",
       textcolor: "red",
       textstyle: "22px Amaranth ,serif",
       text2: "Your mom points.",
       textcolor2: "white",
       textstyle2: "25px Ubuntu,sans",
       buttons: [["Look towards that direction.", "advanceTo(scenario.school6)"]]
  },
  school6: { // Mayor begins talking
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "Ahm, excuse me.",
       textcolor: "#c0c0c0",
       textstyle: "20px Kanit ,serif",
       text2: "An all-too-known voice calls from the front of the room.",
       textcolor2: "white",
       textstyle2: "25px Ubuntu,sans",
       buttons: [["next", "advanceTo(scenario.school7)"]]
  },
  school7: { // Mayor talks
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "Everybody looks towards the direction and sees the mayor calling for \
       an undivided attention with the sheriff standing next to him.",
       textcolor: "white",
       textstyle: "25px Ubuntu ,serif",
       text2: "Citizens of Nubatormenta. We understand your worry, and we would like \
       to help alleviate some of that. Sheriff Moore has declared the town \
       unsafe for walking around; please stay inside the school while the \
       situation gets sorted out. More updates to come.",
       textcolor2: "#c0c0c0",
       textstyle2: "20px Kanit,sans",
       buttons: [["next", "advanceTo(scenario.school8)"]]
  },
  school8: { // Advancing story
       image: "",
       background: "",
       character1: "",
       character2: "mom.png",
       text: "Everyone is dismissed... \
       Stay safe.",
       textcolor: "#c0c0c0",
       textstyle: "20px Kanit ,serif",
       text2: "You heard him, be careful. I'll keep Billy with me.",
       textcolor2: "red",
       textstyle2: "22px Amaranth,sans",
       buttons: [["'Sure thing.'", "advanceTo(scenario.school9)"],["Nod","advanceTo(scenario.school9)"]]
  },
  school9: { // Choosing where to go after cafeteria
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "You leave the cafeteria and head towards the hallway.",
       textcolor: "white",
       textstyle: "25px Ubuntu ,serif",
       text2: "Where do you go?",
       textcolor2: "white",
       textstyle2: "28px 'Press Start 2P',sans",
       buttons: [["Classroom 1", "advanceTo(scenario.barnes1)"],["Classroom 2","advanceTo(scenario.mcking1)"],["Power room","advanceTo(scenario.power1)"],["Gymnasium","advanceTo(scenario.gym1)"]]
  },
  barnes1: { // Barnes' classroom
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "You take a left from the cafeteria and arrive at an open door leading \
       to Barnes' classroom. There are a few children sitting around, playing \
       some sort of children's card game.",
       textcolor: "white",
       textstyle: "22px Ubuntu ,serif",
       text2: "Hey! Wanna join us?",
       textcolor2: "yellow",
       textstyle2: "22px Trirong,sans",
       buttons: [["'Nah, thanks for the offer though.'", "advanceTo(scenario.barnes2)"],["'Don't know how to play that, sorry.'","advanceTo(scenario.barnes3)"]]
  },
  barnes2: { // First response of barnes1
       image: "",
       background: "",
       character1: "harry.png",
       character2: "jacky.png",
       text: "Dang, we needed one more for a full field...",
       textcolor: "#add8e6",
       textstyle: "22px Ubuntu ,serif",
       text2: "Hey, it's okay Harrison.",
       textcolor2: "yellow",
       textstyle2: "22px Trirong,sans",
       buttons: [["'Hey, what are your names?'", "advanceTo(scenario.barnes4)"]]
  },
  barnes3: { // Second response of barnes2
       image: "",
       background: "",
       character1: "harry.png",
       character2: "",
       text: "It's okay, we can teach you!",
       textcolor: "#add8e6",
       textstyle: "22px Ubuntu ,serif",
       text2: "",
       textcolor2: "",
       textstyle2: "",
       buttons: [["'Thanks, but I'll decline. What are your names?'", "advanceTo(scenario.barnes4)"]]
  },
  barnes4: { // Children introducing themselves
       image: "",
       background: "",
       character1: "jacky.png",
       character2: "olga.png",
       text: "Well, my name's Jacky!",
       textcolor: "#b8cc08",
       textstyle: "22px Trirong ,serif",
       text2: "Hi, I'm Olga.",
       textcolor2: "#aec6cf",
       textstyle2: "22px 'Caveat Brush',sans",
       buttons: [["next", "advanceTo(scenario.barnes5)"]]
  },
  barnes5: { // What to talk about
       image: "",
       background: "",
       character1: "harry.png",
       character2: "",
       text: "And I'm Harrison. Do you need anything?",
       textcolor: "#ff8300",
       textstyle: "22px Pacifico,serif",
       text2: "What do you say?",
       textcolor2: "#000000",
       textstyle2: "22px Ubuntu,sans",
       buttons: [["'Do you have any plan for the thing outside?'", "advanceTo(scenario.ufo)"],["'Nah, thanks though.' You head back.","advanceTo(scenario.school10)"]]
  },
  /*barnes6: { // Who to talk to
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "And I'm Harrison. Do you need anything?",
       textcolor: "#add8e6",
       textstyle: "20px Pacifico,serif",
       text2: "What do you say?",
       textcolor2: "#000000",
       textstyle2: "20px Ubuntu,sans",
       buttons: [["'Do you have any plan for the thing outside?'", "advanceTo(scenario.ufo)"],["'Nah, thanks though.' You head back.","advanceTo(scenario.school10)"]]
 },*/
  ufo: { // Who to talk to
      image: "",
      background: "",
      character1: "",
      character2: "",
      text: "Who do you talk to?",
      textcolor: "white",
      textstyle: "20px 'Press Start 2P',serif",
      text2: "",
      textcolor2: "#000000",
      textstyle2: "20px Ubuntu,sans",
      buttons: [["Harrison", "advanceTo(scenario.ufoharry)"],["Jacky","advanceTo(scenario.ufojacky)"],["Olga","advanceTo(scenario.ufoolga)"]]
  },
  ufoharry: { // Harrison's opinion
      image: "",
      background: "",
      character1: "harry.png",
      character2: "",
      text: "What's a UFO? That glowing thing in the distance? \
      That's nothing we have to worry about. The cop said everything will be A-OK.",
      textcolor: "#ff8300",
      textstyle: "22px Pacifico,serif",
      text2: "Hey, did you know that 1 in 12 people live near an active \
      or potentially active volcano?",
      textcolor2: "#ff8300",
      textstyle2: "22px Pacifico,sans",
      buttons: [["Talk to somebody else", "advanceTo(scenario.ufo)"],["Leave","advanceTo(scenario.school10)"]]
  },
  ufojacky: { // Jacky's opinon
      image: "",
      background: "",
      character1: "jacky.png",
      character2: "",
      text: "Figuring out what that thing is would be cool. \
      Maybe go exploring around the school; there's a few people around.",
      textcolor: "#b8cc08",
      textstyle: "22px Trirong,serif",
      text2: "",
      textcolor2: "#000000",
      textstyle2: "20px Ubuntu,sans",
      buttons: [["Talk to somebody else", "advanceTo(scenario.ufo)"],["Leave","advanceTo(scenario.school10)"]]
  },
  ufoolga: { // Olga's opinion
      image: "",
      background: "",
      character1: "olga.png",
      character2: "",
      text: "I'm not too sure, it looks kinda menacing. \
      I also saw something move towards the power room, maybe check it out.",
      textcolor: "#aec6cf",
      textstyle: "22px 'Caveat Brush',serif",
      text2: "",
      textcolor2: "#000000",
      textstyle2: "20px Ubuntu,sans",
      buttons: [["Talk to somebody else", "advanceTo(scenario.ufo)"],["Leave","advanceTo(scenario.school10)"]]
  },
  mcking1: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "You take a right from the cafeteria and arrive at a few classrooms, \
       only one of which has a light coming out from it. It’s McKing’s \
       classroom, one where you spent most of your 8th grade year.",
       textcolor: "white",
       textstyle: "25px Ubuntu ,serif",
       text2: "There's a few people you recognize: the family friends (the Durtons) \
       and your own family. Mom is comforting a very, very worried Billy.",
       textcolor2: "$c0c0c0",
       textstyle2: "22px Kanit,sans",
       buttons: [["'Hey mom, Mr and Mrs Durton.'", "advanceTo(scenario.mcking2)"]]
  },
  mcking2: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "How's it going, bud?",
       textcolor: "#006400",
       textstyle: "20px 'Nixie One',serif",
       text2: "",
       textcolor2: "$c0c0c0",
       textstyle2: "20px Kanit,sans",
       buttons: [["'Nothing much, can I ask you something?'", "advanceTo(scenario.mcking3)"],["'Good, I was just saying hi.'","advanceTo(scenario.school10)"]]
  },
  mcking3: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "Oh, you want to ask about that UFO thing, right? \
       Well let me tell you this: I don't trust the mayor and sheriff; \
       they're hiding something from us. \
       Something bad is happening, and I can feel it.",
       textcolor: "#006400",
       textstyle: "20px 'Nixie One',serif",
       text2: "",
       textcolor2: "$c0c0c0",
       textstyle2: "20px Kanit,sans",
       buttons: [["'What should I do?'", "advanceTo(scenario.mcking4)"],["'Thanks.' You head back.","advanceTo(scenario.school10)"]]
  },
  mcking4: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "Boy, you ask too many questions! \
       Look around the school, see if you can find something amiss. \
       There's bound to be that fine print we haven't read.",
       textcolor: "#006400",
       textstyle: "20px 'Nixie One',serif",
       text2: "",
       textcolor2: "$c0c0c0",
       textstyle2: "20px Kanit,sans",
       buttons: [["'Thank you.' You head back.", "advanceTo(scenario.school10)"]]
  },
  power1: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "You make your way to the power room, the room you had always wanted to \
       see as a student at Hill Valley Middle. It provided backup power on \
       multiple occasions when the power plant could not; reliability was \
       always a key aspect in maintaining operations.",
       textcolor: "white",
       textstyle: "25px Ubuntu ,serif",
       text2: "",
       textcolor2: "$c0c0c0",
       textstyle2: "20px Kanit,sans",
       buttons: [["continue", "advanceTo(scenario.power2)"]]
  },
  power2: {
         image: "",
         background: "",
         character1: "",
         character2: "",
         text: "The door was slightly open when you arrived. After a futile attempt to  \
         turn on the lights, you take out your phone and use its flash. \
         There's a note.",
         textcolor: "white",
         textstyle: "25px Ubuntu ,serif",
         text2: "Worry about the whole of the people.",
         textcolor2: "white",
         textstyle2: "27px 'Nothing You Could Do',sans",
         buttons: [["next", "advanceTo(scenario.power3)"]]
    },
    power3: {
           image: "",
           background: "",
           character1: "",
           character2: "",
           text: "You also notice that the master switch for the backup lights on a \
           dimmed setting, even though they should not be.",
           textcolor: "white",
           textstyle: "20px Ubuntu ,serif",
           text2: "What do you do?",
           textcolor2: "white",
           textstyle2: "20px 'Press Start 2P',sans",
           buttons: [["Turn the lights on", "advanceTo(scenario.power4)"],["Head back.","advanceTo(scenario.school10)"]]
      },
      power4: {
            image: "",
            background: "",
            character1: "",
            character2: "",
            text: "The switch easily gives way to your efforts; you see the backup \
            lights turn on in the hallways.",
            textcolor: "white",
            textstyle: "25px Ubuntu ,serif",
            text2: "",
            textcolor2: "white",
            textstyle2: "20px 'Press Start 2P',sans",
            buttons: [["Head back.","advanceTo(scenario.school11)"]]
       },
  gym1: {
       image: "hallway.png",
       background: "",
       character1: "",
       character2: "",
       text: "Your footsteps echo through the empty hallways, typically occupied by \
       noisy middle school students, as you walk towards your destination. It \
       is slightly difficult to see the correct path as the lights were on a \
       dim setting, seemingly to conserve power.",
       textcolor: "white",
       textstyle: "25px Ubuntu ,serif",
       text2: "",
       textcolor2: "$c0c0c0",
       textstyle2: "20px Kanit,sans",
       buttons: [["continue", "advanceTo(scenario.gym2)"]]
  },
  gym2: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "But the lights were never on a dim setting. \
       They were always either on or off...",
       textcolor: "white",
       textstyle: "25px Ubuntu ,serif",
       text2: "",
       textcolor2: "$c0c0c0",
       textstyle2: "20px Kanit,sans",
       buttons: [["continue", "advanceTo(scenario.gym3)"]]
  },
  gym3: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "You take out your phone and use its camera flash as a light,  \
       illuminating a plaque reading 'Hill Valley Middle School Gymnasium.' \
       You attempt to open the door, but it’s locked.",
       textcolor: "white",
       textstyle: "25px Ubuntu ,serif",
       text2: "",
       textcolor2: "$c0c0c0",
       textstyle2: "20px Kanit,sans",
       buttons: [["Head back", "advanceTo(scenario.school10)"]]
  },
  school10: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "You walk back to the central hallway and rotunda.",
       textcolor: "white",
       textstyle: "25px Ubuntu ,serif",
       text2: "Where do you go?",
       textcolor2: "white",
       textstyle2: "28px 'Press Start 2P',sans",
       buttons: [[["Classroom 1", "advanceTo(scenario.barnes1)"],["Classroom 2","advanceTo(scenario.mcking1)"],["Power room","advanceTo(scenario.power)"],["Gymnasium","advanceTo(scenario.gym)"]]]
  },
  school11: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "You walk back to the central hallway and rotunda. \
       There's a sign posted on the wall:",
       textcolor: "white",
       textstyle: "25px Ubuntu ,serif",
       text2: "Reminder from the mayor: do not walk outside unless \
       otherwise told. It is dangerous and we cannot risk having someone injured.",
       textcolor2: "#c0c0c0",
       textstyle2: "27px 'Nothing You Could Do',sans",
       buttons: [["Head outside anyways.","advanceTo(scenario.school12)"]]
  },
  school12: {
       image: "",
       background: "",
       character1: "",
       character2: "",
       text: "Part II",
       textcolor: "white",
       textstyle: "bold 50px Limelight ,serif",
       text2: "The Five Hours",
       textcolor2: "white",
       textstyle2: "bold 50px Limelight,sans",
       buttons: [["Under construction","advanceTo(scenario.school13)"]]
  },
};

//Begins actual game, everything above is just defined
advanceTo(scenario.prologueentry)
