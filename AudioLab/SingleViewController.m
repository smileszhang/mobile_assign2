//
//  ViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "SingleViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "SMUGraphHelper.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 2048*4
#define INTERVEL 5.38
@interface SingleViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;

//@property (weak, nonatomic) IBOutlet UILabel *testLabel;

@end



@implementation SingleViewController


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
    
    __block SingleViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    [self.audioManager play];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //maxIndex=0;
    //secIndex=0;
    [self.audioManager pause];
    
}


float singlemax=-1000;
float singleindex=0;

-(void)findloudestFrequency:(float*)fftMagnitude{
    float max=fftMagnitude[0];
    int maxindex=0;
    float maxall[2];
    for(int i=0;i<BUFFER_SIZE/2;i++){
        if(fftMagnitude[i]>max){
            max=fftMagnitude[i];
            maxindex=i;
        }
    }
    
    if(max>singlemax){
        singlemax=max;
        singleindex=maxindex*INTERVEL;
    }
    //self.testLabel.textColor=[UIColor whiteColor];
    //self.testLabel.text=[NSString stringWithFormat:@"lll:%f",singleindex ];
    
    
    // [self.view addSubview:self.pianolabel];
}


-(float*)secloudestFrequency:(float)maxindex:(float*)fftMagnitude{
    int secValue=fftMagnitude[0];
    float secindex=0;
    float secall[2];
    for(int i=0;i<BUFFER_SIZE/2;i++){
        if(i==maxindex/INTERVEL)
            continue;
        else if(fftMagnitude[i]>secValue){
            secValue=fftMagnitude[i] ;
            secindex=i;
        }
    }
    secall[0]=secValue;
    secall[1]=secindex*INTERVEL;
    return secall;
}
//
//-(BOOL)judgePiano:(float*)fftMagnitude{
//    float fq_A2=7232;
//    float lrange=fq_A2-INTERVEL/2;
//    float hrange=fq_A2+INTERVEL/2;
//    float realfq=[self findloudestFrequency:fftMagnitude][0];
//    if(realfq>lrange&&realfq<hrange){
//        return YES;
//    }
//    else
//        return NO;
//}

//float final_max=-1000;
//float final_sec=-1000;
//
//float maxIndex,secIndex;
//
//
//-(void)twoLoudestFrequency:(float*)fftMagnitude{
//
//    float arrayTwodim[2][BUFFER_SIZE/2];
//
//    for(int i=0;i<BUFFER_SIZE/2;i++){
//        if(i>=BUFFER_SIZE/2-10&&i<BUFFER_SIZE/2){
//            arrayTwodim[0][i]=-1000;
//            continue;
//        }
//
//        float max=fftMagnitude[i];
//        int maxindex=i;
//        for(int j = i; j < i+10; j++){
//            if(fftMagnitude[j]>max){
//                max=fftMagnitude[j];
//                maxindex=j;
//            }
//        }
//        arrayTwodim[0][i]=max;
//        arrayTwodim[1][i]=maxindex;
//    }
//
//    //build peak array
//    float arrayPeak[BUFFER_SIZE/2];
//    float arrayPeak2[BUFFER_SIZE/2];
//
//    //delete repeat magnitute value
//    arrayPeak[0]=arrayTwodim[0][0];
//    int j=1;
//
//    for(int i=1;i<BUFFER_SIZE/2;i++){
//        if(arrayTwodim[0][i]!=arrayTwodim[0][i-1]){
//            arrayPeak[j]=arrayTwodim[0][i];
//            j++;
//        }
//    }
//    //find the peak
//    int k=0;
//    for(int i=1;i<BUFFER_SIZE/2;i++){
//        if(arrayPeak[i]==-1000){
//            NSLog(@"eee");
//            break;
//
//        }
//        if(arrayPeak[i]>arrayPeak[i-1]&&arrayPeak[i]>arrayPeak[i+1]){
//            arrayPeak2[k]=arrayPeak[i];
//            k++;
//        }
//    }
//
//    //compute max and second max magnitude
//    arrayPeak2[k]=-1000;
//    float max=arrayPeak2[0];
//    float sec=-1000;
//
//
//    for(int i=0;i<BUFFER_SIZE/2;i++){
//        if(arrayPeak2[i]==-1000)
//            break;
//        if(arrayPeak2[i]>max)
//            max=arrayPeak2[i];
//    }
//
//    for(int i=0;i<BUFFER_SIZE/2;i++){
//        if(arrayPeak2[i]==-1000)
//            break;
//        if(arrayPeak2[i]==max)
//            continue;
//        else
//            if(arrayPeak2[i]>sec)
//                sec=arrayPeak2[i];
//    }
//
//    //lock in last two loudest tone
//
//    if(max>final_max){
//        final_max=max;
//        //find max index
//        for(int i=0;i<BUFFER_SIZE/2;i++){
//            if(arrayTwodim[0][i]==final_max){
//                maxIndex=arrayTwodim[1][i];
//                maxIndex=maxIndex*INTERVEL;
//                break;
//            }
//        }
//    }
//    else if(max>final_sec){
//        final_sec=max;
//        //find max index
//        for(int i=0;i<BUFFER_SIZE/2;i++){
//            if(arrayTwodim[0][i]==final_sec){
//                maxIndex=arrayTwodim[1][i];
//                maxIndex=maxIndex*INTERVEL;
//                break;
//            }
//        }
//    }
//
//
//
//    if(sec>final_sec){
//        final_sec=sec;
//
//        //find second max index
//        for(int i=0;i<BUFFER_SIZE/2;i++){
//            if(arrayTwodim[0][i]==final_sec){
//                secIndex=arrayTwodim[1][i];
//                secIndex=secIndex*INTERVEL;
//
//                break;
//            }
//        }
//    }
//
//    //    NSLog(@"dump %f", INTERVEL);
//    //
//    //    float tmpMax = 0.0;
//    //    vDSP_maxv(fftMagnitude, 1, &tmpMax, BUFFER_SIZE/2);
//    //    NSLog(@"tmpMax %f", tmpMax);
//    //    for(int i=0; i < BUFFER_SIZE/2; i++) {
//    //        if (fftMagnitude[i] == tmpMax) {
//    //            NSLog(@"tmpMax index %d", i);
//    //        }
//    //    }
//
//
//
//}
//
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
    
    // [self twoLoudestFrequency:fftMagnitude];
    
    
    [self findloudestFrequency:fftMagnitude];
    
    /*
     if([self judgePiano:fftMagnitude]){
     [self performSegueWithIdentifier:@"transfer" sender:nil];
     [self.graphHelper update];
     }
     else{
     [self.graphHelper update];
     }
     */
    
    // update the graph
    
    [self.graphHelper update];
    
    free(arrayData);
    free(fftMagnitude);
}



//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}


@end
