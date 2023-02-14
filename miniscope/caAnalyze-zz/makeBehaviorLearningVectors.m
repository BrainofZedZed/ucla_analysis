tones = Cues.tones;

%%

Cues.Lperiod = [tones(4,1) size(dff, 2)];
Cues.Lvector = makeVector(Cues.Lperiod, size(dff, 2));

%%


Cues.BLperiod = [1 tones(4,1)-1];
Cues.ELperiod = [tones(4,1) tones(8,2)];
Cues.LLperiod = [tones(8,1) size(dff, 2)];

Cues.BLvector = makeVector(Cues.BLperiod, size(dff, 2));
Cues.ELvector = makeVector(Cues.ELperiod, size(dff, 2));
Cues.LLvector = makeVector(Cues.LLperiod, size(dff, 2));

%%

HandScore.Freezing.BL.Vector = Cues.BLvector & HandScore.Freezing.Vector;
HandScore.Freezing.EL.Vector = Cues.ELvector & HandScore.Freezing.Vector;
HandScore.Freezing.LL.Vector = Cues.LLvector & HandScore.Freezing.Vector;

HandScore.Platform.BL.Vector = Cues.BLvector & HandScore.Platform.Vector;
HandScore.Platform.EL.Vector = Cues.ELvector & HandScore.Platform.Vector;
HandScore.Platform.LL.Vector = Cues.LLvector & HandScore.Platform.Vector;

%%

HandScore.Freezing.L.Vector = Cues.Lvector & HandScore.Freezing.Vector;
HandScore.Platform.L.Vector = Cues.Lvector & HandScore.Platform.Vector;
Cues.LtoneVector = Cues.Lvector & Cues.toneVector;
Cues.LshockVector = Cues.Lvector & Cues.shockVector;



