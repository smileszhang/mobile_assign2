//
//  MBViewController.m
//  AudioLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "MBViewController.h"
#import "Novocaine.h"
#import "CircularBuffer.h"
#import "SMUGraphHelper.h"
#import "FFTHelper.h"

#define BUFFER_SIZE 2048*8

@interface MBViewController ()
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) CircularBuffer *buffer;
@property (strong, nonatomic) SMUGraphHelper *graphHelper;
@property (strong, nonatomic) FFTHelper *fftHelper;



//@property (weak, nonatomic) IBOutlet UILabel *freqLabel;
//@property (weak, nonatomic) IBOutlet UILabel *gestureLabel;
@property (weak, nonatomic) IBOutlet UILabel *freqLabel;
@property (weak, nonatomic) IBOutlet UILabel *gestureLabel;


@property(nonatomic) float frequency;
@property(nonatomic) float phaseIncrement;

@end



@implementation MBViewController

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

-(int)maxFrequencyIndex:(float*)fftMagnitude{
    int indexValue = 0, i = 2048*4-2048*2.5;
    float max = fftMagnitude[i];
        for( i = 2048*4-2048*2.5 ;i < BUFFER_SIZE/2;i++){
            
            if(fftMagnitude[i]>max){
                max=fftMagnitude[i];
                indexValue = i;
            }

        }
    return indexValue;
}


#pragma mark VC Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self updateFrequencyInKHz:17.0];
    
    self.phaseIncrement = 2*M_PI*self.frequency/self.audioManager.samplingRate;
    
    __block float phase = 0.0;
    [self.audioManager setOutputBlock:^(float* data, UInt32 numFrames, UInt32 numChannels){
        
        for(int i=0;i<numFrames;i++){
            for(int j=0;j<numChannels;j++){
                
                data[i*numChannels+j] = sin(phase);
            }
            phase += self.phaseIncrement;
            
            if(phase > 2*M_PI){
                phase -= 2*M_PI;
            }
            
        }
        
    }];

  /*  if( > ) {
        
        self.gestureLabel.text = @"Your hand is towards to the MIC";
        NSLog(@"%f",20*log10(fabs(sin(self.frequency*2*M_PI))));
    }
    else if(sin(phase - self.phaseIncrement*2) > 0.5* 20*log10(fabs(sin(_frequency*2*M_PI)))){
        self.gestureLabel.text = @"Your hand  is leaving the MIC";
    }
    else
        self.gestureLabel.text = @"nothing happenned";  */
    
    
    
    [self.graphHelper setScreenBoundsBottomHalf];
    
    __block MBViewController * __weak  weakSelf = self;
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels){
        [weakSelf.buffer addNewFloatData:data withNumSamples:numFrames];
    }];
    
    [self.audioManager play];
    
}

- (IBAction)frequencyChanged:(UISlider *)sender {
    [self updateFrequencyInKHz:sender.value];
}

/*- (IBAction)frequencyChanged:(UISlider *)sender {
     [self updateFrequencyInKHz:sender.value];
}*/


-(void)updateFrequencyInKHz:(float)freqInKHz{
    self.frequency = freqInKHz*1000.0;
    self.freqLabel.text = [NSString stringWithFormat:@"%.4f KHz", freqInKHz];
    self.phaseIncrement = 2*M_PI*self.frequency/self.audioManager.samplingRate;
    
}

#pragma mark GLK Inherited Functions
//  override the GLKViewController update function, from OpenGLES
- (void)update{
    // just plot the audio stream
    
    // get audio stream data
    float* arrayData = malloc(sizeof(float)*BUFFER_SIZE);
    float* fftMagnitude = malloc(sizeof(float)*BUFFER_SIZE/2);
    
    [self.buffer fetchFreshData:arrayData withNumSamples:BUFFER_SIZE];
    
    //send off for graphing
    [self.graphHelper setGraphData:arrayData
                    withDataLength:BUFFER_SIZE
                     forGraphIndex:0];
    
    // take forward FFT
    [self.fftHelper performForwardFFTWithData:arrayData
                   andCopydBMagnitudeToBuffer:fftMagnitude];
    
    
    
    
   /* float fftMagnitudeDecibel[BUFFER_SIZE/2];
     
     for(int i = 0; i < BUFFER_SIZE/2; i++){
     
     fftMagnitudeDecibel[i] = 20*log10(fabs(fftMagnitude[i]));
     //NSLog(@"%f", fftMagnitude[i]);
     }*/

    int myIndex = [self maxFrequencyIndex:fftMagnitude];
    if(fftMagnitude[myIndex+2] > 0.4*fftMagnitude[myIndex] && fftMagnitude[myIndex+3] > 0.2*fftMagnitude[myIndex] && fftMagnitude[myIndex+1] > 0.7*fftMagnitude[myIndex]) {
        //if(fftMagnitude[myIndex+2] > 0.05*fftMagnitude[myIndex])
        self.gestureLabel.text = @"Your hand is towards to the MIC";
        
    }
    else if(fftMagnitude[myIndex-3] > 0.205*fftMagnitude[myIndex] && fftMagnitude[myIndex-2] > 0.42*fftMagnitude[myIndex] && fftMagnitude[myIndex-1] > 0.815*fftMagnitude[myIndex]){
        //if(fftMagnitude[myIndex-2] > 0.08*fftMagnitude[myIndex])
        self.gestureLabel.text = @"hand is leaving";
    }
    else
        self.gestureLabel.text = @"Nothing";

    
    // graph the FFT Data
    [self.graphHelper setGraphData:fftMagnitude
                    withDataLength:BUFFER_SIZE/2
                     forGraphIndex:1
                 withNormalization:60.0
                     withZeroValue:-64];
    
    
    
    [self.graphHelper update]; // update the graph
    free(arrayData);
    free(fftMagnitude);
    
}

//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.graphHelper draw]; // draw the graph
}


@end
