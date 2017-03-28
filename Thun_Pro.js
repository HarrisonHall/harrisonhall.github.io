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
    background: "",
    character1: "",
    character2: "",

    text: "PROLOGUE",
    textcolor: "white",
    textstyle: "bold 50px Limelight,serif",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",

    buttons: [["START", "advanceTo(scenario.begin)"]]
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

  buttons: [["PROLOGUE", "advanceTo(scenario.prologue)"]]
},
  prologue: {
    image: "http://www.solidbackgrounds.com/images/2560x1440/2560x1440-black-solid-color-background.jpg", //dog
    character1: "",
    character2: "",
    background: "",
    textcolor: "white",
    textstyle: "bold 26px Ubuntu,serif",
    text: "What happens when an unstoppable force meets an immovable object? \
          This is called the irresistible force paradox. A classic paradox, this \
          question has left many questioning the results of the incompatible circumstances.\
          Thundercloud is a story about parodoxes. A story about choices. A story \
          about events one cannot understand, that just shouldn't occur.",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",
    buttons: [["CONTINUE", "advanceTo(scenario.two)"]]
  },
  two: {
    image: "http://wallpapercave.com/wp/Ard7vgo.jpg", //house
    character1: "http://vignette4.wikia.nocookie.net/pokemon/images/d/d7/MaxAG.png/revision/latest?cb=20150527094843",
    character2: "",
    background: "",
    text: "Brother! Wake up! What's going on?",
    textstyle: "25px 'Orbitron',sans-serif",
    textcolor: "#5533FF",
    text2: "",
    buttons: [["Yawn", "advanceTo(scenario.three)"],["'Why would I know?'", "advanceTo(scenario.three)"]]
  },
  three: {
    image: "http://data.whicdn.com/images/8433529/tumblr_liz1hm0UuE1qhawe0o1_500_large.jpg?1301723003",
    character1: "",
    character2: " ",
    text: "You quickly get up, realizing that the ground under you is rumbling. \
          A strange bliding light fills the midnight sky as you quickly pack up \
          the most important items you took along to your weekend camping trip. \
          You quickly realize that that would be impossible.",
    textcolor: "white",
    textstyle: "35px Ubuntu,sans",
    text2: "What do you take?",
    textcolor2: "white",
    textstyle2: "30px 'Press Start 2P',sans",
    buttons: [["Water bottles", "advanceTo(scenario.water)"],["Beef jerky","advanceTo(scenario.beef)"],["Flashlight", "advanceTo(scenario.flash)"],["Hatchet", "advanceTo(scenario.hatchet)"]]
  },
  water: {
    image: "",
    background: "",
    character1: "",
    character2: "",
    text: "You grabbed the water bottles.",
    textcolor: "white",
    textstyle: "bold 50px Limelight,serif",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",
    buttons: [["continue", "advanceTo(scenario.four)"]]
  },
   beef: {
    image: "",
    background: "",
    character1: "",
    character2: "",
    text: "You grabbed the beef jerky.",
    textcolor: "white",
    textstyle: "bold 50px Limelight,serif",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",
    buttons: [["continue", "advanceTo(scenario.four)"]]
},
  flash: {
    image: "",
    background: "",
    character1: "",
    character2: "",
    text: "You grabbed the flashlight.",
    textcolor: "white",
    textstyle: "50px Limelight,serif",
    text2: "",
    textcolor2: "blue",
    textstyle2: "40px Indie Flower,sans",
    buttons: [["continue", "advanceTo(scenario.four)"]]
  },

  hatchet: {
    text: "You grabbed the hatchet.",
    text2: "",
    image: "http://worldartsme.com/images/hatchet-book-clipart-1.jpg",
    buttons: [["continue", "advanceTo(scenario.four)"]]
  },

  four: {
      image: "",
      background: "",
      character1: "",
      character2: "",
      text: "You quickly race to your modest house. The sky continues to darken as\
      the light begins to gain a faint purple tint.",
      textcolor: "white",
      textstyle: "50px Ubuntu,serif",
      text2: "A dark figure emerges.",
      textcolor2: "gray",
      textstyle2: "40px Indie Flower,sans",
      buttons: [["continue", "advanceTo(scenario.five)"]]
  },

  five: {
    image: "",
    text: "Your brother continues running as a dark figure confronts you.",
    text2: "'Schroder!'",
    textcolor2: "red",
    textstyle2: "40px Boogaloo,sans",
    buttons: [["Continue running", "advanceTo(scenario.six)"],["Confront the figure", "advanceTo(scenario.maelstrom)"]]
  },

  six: {
    image: "",
    text: "You reach the city as a loud BOOM echoes from the sky.",
    textcolor: "white",
    textstyle: "40px Ubuntu,sans",
    text2: "",
    buttons: [["The PRESENT TRIAL", "advanceTo(scenario.trial1)"]]
  },

  maelstrom: {
    image: "",
    text: "You the voice as a cloaked figure emerges from the darkness.",
    text2: "'Save the ones you love most.'",
    textcolor2: "red",
    textstyle2: "40px Boogaloo,sans",
    buttons: [["continue", "advanceTo(scenario.maestrom2)"]]
  },

  maestrom2: {
    image: "",
    text: "You hear the voice as a cloaked figure emerges from the darkness.",
    text2: "'Save the ones you love most.'",
    textcolor2: "red",
    textstyle2: "40px Boogaloo,sans",
    buttons: [["continue", "advanceTo(scenario.six)"]]
  },

  trial1: {
    image: "",
    background: "",
    character1: "",
    character2: "",
    text: "You finally make your way home. Your brother is already inside waiting on \
    you. As soon as you enter the doorway, you see Billy running around the house.",
    textcolor: "white",
    textstyle: "bold 50px Ubuntu,serif",
    text2: "Mom isn't here!",
    textcolor2: "#5533FF",
    textstyle2: "40px Orbitron,sans",
    buttons: [["Help Billy Search the house.", "advanceTo(scenario.b4school)"],["Grab Billy and find Mom.", "advanceTo(scenario.b4school)"]]
  },

  b4school: {
    image: "",
    background: "",
    character1: "",
    character2: "",
    text: "You quickly search your home, but ultimately decide to go the the safest \
    place in town, the school. As you reach Hill Valley Middle School, you see floodlights \
    being set up by a few members of the town. As you reach the school, you manage to make out the face of your coworker.",
    textcolor: "white",
    textstyle: "bold 50px Ubuntu,serif",
    text2: "",
    textcolor2: "#5533FF",
    textstyle2: "40px Orbitron,sans",
    buttons: [["Continue", "advanceTo(scenario.whatever)"]]
  },

};

//Begins actual game, everything above is just defined
advanceTo(scenario.prologueentry)
