import intel.pcsdk.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

short[] depthMap;
int[] depthMapSize = new int[2];

PXCUPipeline session;

Minim mnm;
AudioPlayer track;
FFT fft;

void setup()
{
  size(640, 480, P3D);
  stroke(0, 255, 0);
  strokeWeight(1);
  noFill();

  session = new PXCUPipeline(this);
  if(!session.Init(PXCUPipeline.DEPTH_QVGA))
    exit();

  session.QueryDepthMapSize(depthMapSize);
  depthMap = new short[depthMapSize[0] * depthMapSize[1]];
  
  mnm = new Minim(this);
  track = mnm.loadFile("drawback.mp3", 2048);
  track.cue(60000);
  track.play();
  fft = new FFT(track.bufferSize(), track.sampleRate());
  fft.logAverages(22,6);
}

void draw()
{
  background(0);

  translate(width/2, height/2, 0);  
  rotateY(radians(180+mouseX));

  if(session.AcquireFrame(false))
  {
    session.QueryDepthMap(depthMap);
    session.ReleaseFrame();
  }
    
  fft.forward(track.mix);
  for (int y = 0; y < depthMapSize[1]; y+=2)
  {
    beginShape(LINES);
    int band = (int)constrain(map(y,0,depthMapSize[1],0,fft.avgSize()-1),0,fft.avgSize()-1);
    //band = (fft.avgSize()-1)-band;
    //int band = (int)constrain(map(y,0,depthMapSize[1],0,fft.specSize()-1),0,fft.specSize()-1);
    for (int x = 0; x < depthMapSize[0]; x+=4)
    {
      int i_p = y*320+x;
      int px = (int)(map(x, 0, depthMapSize[0], -320, 320));
      int py = (int)(map(y, 0, depthMapSize[1], -240, 240));
      float dv = constrain(map(depthMap[i_p],0,1500,0,640),0,640);
      //float amp = constrain(map(fft.getAvg(band),0,512,0,100),0,100);
      float amp = fft.getAvg(band);
      //float amp = fft.getBand(band)*10;
      if(depthMap[i_p]<32000)
      {
        stroke(0,255,255);
        strokeWeight(5);
        vertex(px-1,py,dv);
        stroke(255,0,255);
        strokeWeight(1);
        vertex(px,py,dv-amp);
      }

    }
    endShape();    
  }
}

void stop()
{
  track.close();
  mnm.stop();
  super.stop();
}

