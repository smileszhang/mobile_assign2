//
//  ViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "ViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "SMUGraphHelper.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 2048*8
#define INTERVEL 2.69165039
#define WINDOW_SIZE 18
#define WINDOW_SIZE2 2
@interface ViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;
@property (weak, nonatomic) IBOutlet UILabel *secFreLabel;
@property (weak, nonatomic) IBOutlet UILabel *frequencLabel;
@property (weak, nonatomic) IBOutlet UILabel *pianoLabel;
@property (weak, nonatomic) IBOutlet UILabel *pianoLabel2;
@property (weak, nonatomic) IBOutlet UILabel *showPiano;
@property (weak, nonatomic) IBOutlet UILabel *showPiano2;

@end



@implementation ViewController


#pragma mark Lazy Instantiation


-(Novocaine*)audioManager{
    if(!_audioManager){
        _audioManager = [Novocaine audioManager];
    }
    return _audioManager;
}

-(CircularBuffer*)buffer{
    if(!_buffer){
        _buffer = [[CircularBuffer alloc]initWithNumChannels:1 andBufferSize:BUFFER_SIZE];
    }
    return _buffer;
}

-(SMUGraphHelper*)graphHelper{
    if(!_graphHelper){
        _graphHelper = [[SMUGraphHelper alloc]initWithController:self
                                        preferredFramesPerSecond:15
                                                       numGraphs:2
                                                       plotStyle:PlotStyleSeparated
                                               maxPointsPerGraph:BUFFER_SIZE];
    }
    return _graphHelper;
}

-(FFTHelper*)fftHelper{
    if(!_fftHelper){
        _fftHelper = [[FFTHelper alloc]initWithFFTSize:BUFFER_SIZE];
    }
    
    return _fftHelper;
}


#pragma mark VC Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self.graphHelper setFullScreenBounds];
    
    __block ViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    [self.audioManager play];

}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    maxIndex=0;
    secIndex=0;
    final_max=-1000;
    final_sec=-1000;
    piano_max=-1000;
    piano_sec=-1000;
    pianomaxIndex=0;
    pianosecIndex=0;
    
    [self.audioManager pause];
    
}




//-(float*)findloudestFrequency:(float*)fftMagnitude{
//    float max=fftMagnitude[0];
//    int maxindex=0;
//    float maxall[2];
//    for(int i=0;i<BUFFER_SIZE/2;i++){
//        if(fftMagnitude[i]>max){
//            max=fftMagnitude[i];
//            maxindex=i;
//        }
//    }
//    maxall[0]=max;
//    maxall[1]=maxindex*INTERVEL;
//    return maxall;
//}
//
//
//-(float*)secloudestFrequency:(float)maxindex:(float*)fftMagnitude{
//    int secValue=fftMagnitude[0];
//    float secindex=0;
//    float secall[2];
//    for(int i=0;i<BUFFER_SIZE/2;i++){
//        if(i==maxindex/INTERVEL)
//            continue;
//        else if(fftMagnitude[i]>secValue){
//            secValue=fftMagnitude[i] ;
//            secindex=i;
//        }
//    }
//    secall[0]=secValue;
//    secall[1]=secindex*INTERVEL;
//    return secall;
//}
//
float piano_max=-1000;
float piano_sec=-1000;

float pianomaxIndex,pianosecIndex;

-(void)judgePiano:(float*)fftMagnitude{
    float pianoPitch[78];
    NSString*pianoName[78];
    pianoPitch[0]=110;
    pianoPitch[1]=116.54;
    pianoPitch[2]=123.47;
    pianoName[0]=@"A2";
    pianoName[1]=@"A#2";
    pianoName[2]=@"B2";
    
    int p=3;
    for(int i=3;i<78;i++){
       //frequency for each tone
        pianoPitch[i]=pianoPitch[i-1]*1.0594631;
        //name for each tone
        switch(i%12){
            case 3:pianoName[i]=[@"C" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 4:pianoName[i]=[@"C#" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 5:pianoName[i]=[@"D" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 6:pianoName[i]=[@"D#" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 7:pianoName[i]=[@"E" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 8:pianoName[i]=[@"F" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 9:pianoName[i]=[@"F#" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 10:pianoName[i]=[@"G" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 11:pianoName[i]=[@"G#" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 0:pianoName[i]=[@"A" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 1:pianoName[i]=[@"A#" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;
            case 2:pianoName[i]=[@"B" stringByAppendingString:[NSString stringWithFormat:@"%d",p]];break;

        }
        
        if(i%12==2)
            p++;
    }
    
    //find two loudest tone
    
    float arrayTwodim[2][BUFFER_SIZE/2]={0};
    
    for(int i=0;i<BUFFER_SIZE/2;i++){
        if(i>=BUFFER_SIZE/2-WINDOW_SIZE2&&i<BUFFER_SIZE/2){
            arrayTwodim[0][i]=-1000;
            continue;
        }
        
        float max=fftMagnitude[i];
        int maxindex1=i;
        for(int j = i; j < i+WINDOW_SIZE2; j++){
            if(fftMagnitude[j]>max){
                max=fftMagnitude[j];
                maxindex1=j;
            }
        }
        arrayTwodim[0][i]=max;
        arrayTwodim[1][i]=maxindex1;
    }
    
    //build peak array
   
    float arrayPeak[BUFFER_SIZE/2]={0};
    float arrayPeak2[BUFFER_SIZE/2]={0};
    
   // float *arrayPeak=malloc(sizeof(float)*BUFFER_SIZE/2);
   // float *arrayPeak2=malloc(sizeof(float)*BUFFER_SIZE/2);
    
    //delete repeat magnitute value
    arrayPeak[0]=arrayTwodim[0][0];
    int j=1;
    
    for(int i=1;i<BUFFER_SIZE/2;i++){
        if(arrayTwodim[0][i]!=arrayTwodim[0][i-1]){
            arrayPeak[j]=arrayTwodim[0][i];
            j++;
        }
    }
    //find the peak
    int k=0;
    for(int i=1;i<BUFFER_SIZE/2;i++){
        if(arrayPeak[i]==-1000){
            break;
            
        }
        if(arrayPeak[i]>arrayPeak[i-1]&&arrayPeak[i]>arrayPeak[i+1]){
            arrayPeak2[k]=arrayPeak[i];
            k++;
        }
    }
    
    //compute max and second max magnitude
    arrayPeak2[k]=-1000;
    float max=arrayPeak2[0];
    float sec=-1000;
    
    
    for(int i=0;i<BUFFER_SIZE/2;i++){
        if(arrayPeak2[i]==-1000)
            break;
        if(arrayPeak2[i]>max)
            max=arrayPeak2[i];
    }
    
    for(int i=0;i<BUFFER_SIZE/2;i++){
        if(arrayPeak2[i]==-1000)
            break;
        if(arrayPeak2[i]==max)
            continue;
        else
            if(arrayPeak2[i]>sec)
                sec=arrayPeak2[i];
    }
    
    //lock in last two loudest tone
    
    if(max>piano_max){
        piano_max=max;
        //find max index
        for(int i=0;i<BUFFER_SIZE/2;i++){
            if(arrayTwodim[0][i]==piano_max){
                pianomaxIndex=arrayTwodim[1][i];
                pianomaxIndex=pianomaxIndex*INTERVEL;
                break;
            }
        }
    }
    
    if(sec>piano_sec){
        piano_sec=sec;
        
        //find second max index
        for(int i=0;i<BUFFER_SIZE/2;i++){
            if(arrayTwodim[0][i]==piano_sec){
                pianosecIndex=arrayTwodim[1][i];
                pianosecIndex=pianosecIndex*INTERVEL;
                
                break;
            }
        }
    }

    self.showPiano.textColor=[UIColor whiteColor];
    self.showPiano2.textColor=[UIColor whiteColor];
    self.showPiano.text=[NSString stringWithFormat:@"Loudest frequency: %f",pianomaxIndex];
    self.showPiano2.text=[NSString stringWithFormat:@"Second frequency: %f",pianosecIndex];
    
    [self.view addSubview:self.showPiano];
    
    [self.view addSubview:self.showPiano2];

    
    
    for(int i=0;i<78;i++){
        float halfIntervelLow=0;
        float halfIntervelHigh=0;
        if(i!=0){
            halfIntervelLow=(pianoPitch[i]-pianoPitch[i-1])/2;
        }
        if(i!=77){
            halfIntervelHigh=(pianoPitch[i+1]-pianoPitch[i])/2;

        }
        if(i!=0&&i!=77){
            if(pianomaxIndex>(pianoPitch[i]-halfIntervelLow)&&pianomaxIndex<(pianoPitch[i]+halfIntervelHigh)){
                self.pianoLabel.text=[@"First:" stringByAppendingString:pianoName[i]];
                self.pianoLabel.textColor=[UIColor whiteColor];
                [self.view addSubview:self.pianoLabel];
            }
        }
        else if(i==0){
            if(pianomaxIndex<(pianoPitch[i]+halfIntervelHigh)){
                self.pianoLabel.text=[@"First:" stringByAppendingString:pianoName[i]];
                self.pianoLabel.textColor=[UIColor whiteColor];
                [self.view addSubview:self.pianoLabel];
            }
        }
        else if(i==77){
            if(pianomaxIndex>(pianoPitch[i]-halfIntervelHigh)){
                self.pianoLabel.text=[@"First:" stringByAppendingString:pianoName[i]];
                self.pianoLabel.textColor=[UIColor whiteColor];
                [self.view addSubview:self.pianoLabel];
            }

        }
            }
    
    for(int i=0;i<78;i++){
        float halfIntervelLow=0;
        float halfIntervelHigh=0;
        if(i!=0){
            halfIntervelLow=(pianoPitch[i]-pianoPitch[i-1])/3;
        }
        if(i!=77){
            halfIntervelHigh=(pianoPitch[i+1]-pianoPitch[i])/3;
            
        }
        if(i!=0&&i!=77){
            if(pianosecIndex>(pianoPitch[i]-halfIntervelLow)&&pianosecIndex<(pianoPitch[i]+halfIntervelHigh)){
                self.pianoLabel2.text=[@"Second:" stringByAppendingString:pianoName[i]];
                self.pianoLabel2.textColor=[UIColor whiteColor];
                [self.view addSubview:self.pianoLabel2];
            }
        }
        else if(i==0){
            if(pianosecIndex<(pianoPitch[i]+halfIntervelHigh)&&pianosecIndex>(pianoPitch[i]-halfIntervelHigh)){
                self.pianoLabel2.text=[@"Second:" stringByAppendingString:pianoName[i]];
                self.pianoLabel2.textColor=[UIColor whiteColor];
                [self.view addSubview:self.pianoLabel2];
            }
        }
        else if(i==77){
            if(pianosecIndex>(pianoPitch[i]-halfIntervelHigh)&&pianosecIndex<(pianoPitch[i]+halfIntervelLow)){
                self.pianoLabel2.text=[@"Second:" stringByAppendingString:pianoName[i]];
                self.pianoLabel2.textColor=[UIColor whiteColor];
                [self.view addSubview:self.pianoLabel2];
            }
            
        }
    }
 
    
//    for(int i=0;i<78;i++){
//        if(pianosecIndex>(pianoPitch[i]-halfIntervel)&&pianosecIndex<(pianoPitch[i]+halfIntervel)){
//            self.pianoLabel2.text=[@"Second:" stringByAppendingString:pianoName[i]];
//            self.pianoLabel2.textColor=[UIColor whiteColor];
//            [self.view addSubview:self.pianoLabel2];
//
//        }
//    }
   
    //free(arrayPeak);
    //free(arrayPeak2);

    
}

float final_max=-1000;
float final_sec=-1000;

float maxIndex,secIndex;


-(void)twoLoudestFrequency:(float*)fftMagnitude{

    //float *arrayTwodim=malloc(sizeof(float)*BUFFER_SIZE/2);

    float arrayTwodim[2][BUFFER_SIZE/2]={0};
    
   for(int i=0;i<BUFFER_SIZE/2;i++){
        if(i>=BUFFER_SIZE/2-WINDOW_SIZE&&i<BUFFER_SIZE/2){
            arrayTwodim[0][i]=-1000;
            continue;
        }

            float max=fftMagnitude[i];
            int maxindex1=i;
            for(int j = i; j < i+WINDOW_SIZE; j++){
                if(fftMagnitude[j]>max){
                    max=fftMagnitude[j];
                    maxindex1=j;
                }
            }
            arrayTwodim[0][i]=max;
            arrayTwodim[1][i]=maxindex1;

       
        }
 
    //build peak array
    
    float arrayPeak[BUFFER_SIZE/2]={0};
    float arrayPeak2[BUFFER_SIZE/2]={0};
    //float *arrayPeak=malloc(sizeof(float)*BUFFER_SIZE/2);
   // float *arrayPeak2=malloc(sizeof(float)*BUFFER_SIZE/2);

    //delete repeat magnitute value
    arrayPeak[0]=arrayTwodim[0][0];
    int j=1;

    for(int i=1;i<BUFFER_SIZE/2;i++){
        if(arrayTwodim[0][i]!=arrayTwodim[0][i-1]){
            arrayPeak[j]=arrayTwodim[0][i];
            if(arrayPeak[j]==-1000)
                NSLog(@"11111");
            j++;
        }
    }
    
    //find the peak
    int k=0;
    for(int i=1;i<BUFFER_SIZE/2;i++){
        if(arrayPeak[i]==-1000){
            break;
        }
        if(arrayPeak[i]>arrayPeak[i-1]&&arrayPeak[i]>arrayPeak[i+1]){
            arrayPeak2[k]=arrayPeak[i];
            k++;
        }
    }
    
    //compute max and second max magnitude
    arrayPeak2[k]=-1000;
    float max=arrayPeak2[0];
    float sec=-1000;
    
    
    for(int i=0;i<BUFFER_SIZE/2;i++){
        if(arrayPeak2[i]==-1000)
            break;
        if(arrayPeak2[i]>max)
            max=arrayPeak2[i];
    }
    
    for(int i=0;i<BUFFER_SIZE/2;i++){
        if(arrayPeak2[i]==-1000)
            break;
        if(arrayPeak2[i]==max)
            continue;
        else
            if(arrayPeak2[i]>sec)
                sec=arrayPeak2[i];
    }
    
    //lock in last two loudest tone

    if(max>final_max){
        final_max=max;
        //find max index
        for(int i=0;i<BUFFER_SIZE/2;i++){
            if(arrayTwodim[0][i]==final_max){
                maxIndex=arrayTwodim[1][i];
                maxIndex=maxIndex*INTERVEL;
                break;
            }
        }
    }
    
    if(sec>final_sec){
        final_sec=sec;
        
        //find second max index
        for(int i=0;i<BUFFER_SIZE/2;i++){
            if(arrayTwodim[0][i]==final_sec){
                secIndex=arrayTwodim[1][i];
                secIndex=secIndex*INTERVEL;

                break;
            }
        }
    }
    
        //    NSLog(@"dump %f", INTERVEL);
//    
//    float tmpMax = 0.0;
//    vDSP_maxv(fftMagnitude, 1, &tmpMax, BUFFER_SIZE/2);
//    NSLog(@"tmpMax %f", tmpMax);
//    for(int i=0; i < BUFFER_SIZE/2; i++) {
//        if (fftMagnitude[i] == tmpMax) {
//            NSLog(@"tmpMax index %d", i);
//        }
//    }
    
    
    self.frequencLabel.textColor=[UIColor whiteColor];
    self.secFreLabel.textColor=[UIColor whiteColor];
    self.frequencLabel.text=[NSString stringWithFormat:@"Loudest frequency: %f",maxIndex];
    self.secFreLabel.text=[NSString stringWithFormat:@"Second frequency: %f",secIndex];
    
    [self.view addSubview:self.frequencLabel];
    
    [self.view addSubview:self.secFreLabel];
    
    //free(arrayPeak);
    //free(arrayPeak2);
    
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    //float arrayData[BUFFER_SIZE];
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
  //  float fftMagnitude[BUFFER_SIZE/2];
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    float maxTmp = 0.0;
    vDSP_maxv(fftMagnitude, 1, &maxTmp, BUFFER_SIZE/2);
    NSLog(@"%f", maxTmp);
    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:1
                 withNormalization:64.0
                     withZeroValue:-60];
    
    [self twoLoudestFrequency:fftMagnitude];
    
    [self judgePiano:fftMagnitude];

    
    [self.graphHelper update];

    free(arrayData);
    free(fftMagnitude);
}



//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}


@end
