#import "ExampleViewController.h"
#import "IntroControll.h"

@implementation ExampleViewController

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    self.wantsFullScreenLayout = YES;
    self.modalPresentationStyle = UIModalPresentationFullScreen;
    return self;
}

- (void) loadView {
    [super loadView];
    
    IntroModel *model1 = [[IntroModel alloc]
                          initWithTitle:@"60 – 105 BPM"
                          description:@"Pilates, Yoga, Warm-up, Cooldown, Stretching"
                          image:@"1.png"];

    IntroModel *model2 = [[IntroModel alloc]
                          initWithTitle:@"105 – 125 BPM"
                          description:@"Walking (3 to 3.5 mph), Strength training"
                          image:@"2.png"];

    IntroModel *model3 = [[IntroModel alloc]
                          initWithTitle:@"125 – 140 BPM"
                          description:@"Brisk walking (3.5 to 4.5 mph), Light elliptical, Stairclimbing"
                          image:@"3.png"];

    IntroModel *model4 = [[IntroModel alloc]
                          initWithTitle:@"140 – 160 BPM"
                          description:@"Jogging (4.5 to 5 mph), Elliptical, Stairclimbing"
                          image:@"4.png"];

    IntroModel *model5 = [[IntroModel alloc]
                          initWithTitle:@"160+ BPM"
                          description:@"Running (5 mph or faster), Cycling (80 rpm and above), Jumping rope, Cardio dance"
                          image:@"5.png"];

    self.view = [[IntroControll alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) pages:@[model1, model2, model3, model4, model5]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
