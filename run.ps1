Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms

# HashTable and RunSpace for application

$syncHash = [hashtable]::Synchronized(@{})

#$newRunspace = [runspacefactory]::CreateRunspace()
#$newRunspace.ApartmentState = "STA"
#$newRunspace.ThreadOptions = "ReuseThread"         
#$newRunspace.Open()
#$newRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)      

$sharedFunctions = {
    function Write-StatusProgress ($msg, $pct) {

        $syncHash.Form.Dispatcher.Invoke([action] {
                $syncHash.WPFStatusTextBlock.Text = $msg
                if (-not [string]::IsNullOrEmpty($pct)) {
                    $syncHash.WPFProgressBar.Value = $pct
                }
            }, "Render"
        )
    }
    
    function Write-Error ($msg = 'error') {
    
        $syncHash.Form.Dispatcher.Invoke([action] {
                $syncHash.WPFStatusTextBlock.Text = $msg
                $syncHash.WPFStatusTextBlock.Foreground = 'Red'
                $syncHash.WPFProgressBar.Foreground = 'Red'
            }, "Render"
        )
    }

    function Write-Toast {
Add-Type -AssemblyName System.Windows.Forms
#[System.Windows.Forms.Application]::EnableVisualStyles()
# Load WPF assembly if necessary
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="Window" Height="120" Width="400" ResizeMode="NoResize" ShowInTaskbar="False" Topmost="True" AllowsTransparency="True" Background="Black" Foreground="White" Opacity="0.7" BorderBrush="Red" WindowStyle="None">
    <Grid Margin="0,0,0.5,0">
        <Image Name="Img" HorizontalAlignment="Left" Height="32" Margin="14,14,0,0" VerticalAlignment="Top" Width="32"/>
        <Button Name = "CloseButton" Content="X" HorizontalAlignment="Left" Margin="380,0,-0.5,0" VerticalAlignment="Top" Width="20" Height="20" Background="#FF010101" Foreground="White" BorderBrush="{x:Null}">
        <Button.Style>
    <Style TargetType="{x:Type Button}">
        <Setter Property="Background" Value="Black" />
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="{x:Type Button}">
                    <Border x:Name="Border" Background="{TemplateBinding Background}">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Background" Value="Red" TargetName="Border" />
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
</Button.Style>
        </Button>
        <Label Name="Title" Content="Application name" HorizontalAlignment="Left" Margin="62,9,0,0" VerticalAlignment="Top" Width="298" Height="40" Foreground="White" FontSize="20"/>
        <Label Name="Text" Content="INFO: all seems good" HorizontalAlignment="Left" Margin="62,50,0,10" VerticalAlignment="Center" Width="328" Height="60" Foreground="White" FontSize="15"/>
    </Grid>
</Window>
"@

$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Window=[Windows.Markup.XamlReader]::Load( $reader )

$xaml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name ($_.Name) -Value $Window.FindName($_.Name) -Scope Script }

$Window.Left = $([System.Windows.SystemParameters]::WorkArea.Width-$Window.Width-5) 
$Window.Top = $([System.Windows.SystemParameters]::WorkArea.Height-$Window.Height-5) 

$base64img = "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"

$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64img)
$bitmap.EndInit()
# Freeze() prevents memory leaks.
$bitmap.Freeze()

#$Title = $Window.FindName("Title")
#$Text = $Window.FindName("Text")
#$Button = $Window.FindName("CloseButton")

$Title.Content = "App"
$Text.Foreground = "White"
$Text.Content = "Sample info`n" + (get-date -Format T)
$Img.Source = $bitmap

$delay = 5

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000

#$timer.Add_Tick({
#        $Window.Activate()
#        $timer.Stop()
#        Start-Sleep -Seconds $delay
#        $Window.Close()
#        $timer.Dispose()
#})

$CloseButton.Add_Click({
    $timer.Stop()
    $Window.Hide()
    $Window.Close()
    $timer.Dispose()
})

$timer.start()

$Window.ShowDialog()


    }

}

$syncHash.globalFunctions = "$sharedFunctions"

# Build UI and add to RunSpace
#$psCmd = [PowerShell]::Create().AddScript( {

# Loading global shared functions
Invoke-Expression $syncHash.globalFunctions
        
$inputXML = @"
<Window x:Class="WpfApp2.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp2"
        mc:Ignorable="d"
        Title="startDD" Height="257.616" Width="419.375" MaxHeight="257.616" MaxWidth="419.375" ResizeMode="CanMinimize" ShowInTaskbar="True" Topmost="True">
    <Grid Margin="0,0,0.5,0">
        <Grid.ColumnDefinitions>
            <ColumnDefinition/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition/>
        </Grid.RowDefinitions>
        <CheckBox Name="MRACheckBox" Content="Remoteapp mode" HorizontalAlignment="Left" Margin="12,40,0,0" VerticalAlignment="Top" Height="31" Width="150"/>
        <Button Name="StartButton" Content="Start" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Width="75" Height="20"/>
        <ProgressBar Name="ProgressBar" HorizontalAlignment="Left" Height="10" Margin="100,15,0,0" VerticalAlignment="Top" Width="295"/>
        <Label Content="Status:" HorizontalAlignment="Left" Margin="10,190,0,-52.5" VerticalAlignment="Top" Width="46" Height="26" FontWeight="Bold"/>
        <Label Content="User VMs" HorizontalAlignment="Left" Margin="10,64,0,0" VerticalAlignment="Top" FontWeight="Bold"/>
        <TextBlock Name="StatusTextBlock" HorizontalAlignment="Left" Margin="61,195,0,-57.5" TextWrapping="Wrap" Text="loading..." VerticalAlignment="Top" Width="330" Height="26"/>
        <DataGrid Name="DataGrid" Height="90" HorizontalAlignment="Left" Margin="12,95,0,0" Width="380" HorizontalGridLinesBrush="Gray" VerticalGridLinesBrush="Gray" VerticalAlignment="Top">
            <DataGrid.Columns>
                <DataGridTextColumn Header="State" Binding="{Binding State}" Width="Auto" IsReadOnly="True">
                <DataGridTextColumn.ElementStyle>
                <Style TargetType="{x:Type TextBlock}">
                    <Style.Triggers>
                        <Trigger Property="Text" Value="NOK">
                            <Setter Property="Background" Value="Red"/>
                        </Trigger>
                        <Trigger Property="Text" Value="OK">
                        <Setter Property="Background" Value="LightGreen"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
                </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Name" Binding="{Binding Name}" Width="Auto" IsReadOnly="True"/>
                <DataGridTextColumn Header="IP" Binding="{Binding IP}" Width="Auto" IsReadOnly="True"/>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="Auto" IsReadOnly="True"/>
                <DataGridTextColumn Header="Expiration" Binding="{Binding Expiration}" Width="1*" IsReadOnly="True"/>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</Window>
"@

$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')

        

[xml]$xaml = $inputXML

# Read XAML 
$reader = (New-Object System.Xml.XmlNodeReader $xaml) 
$syncHash.Form = [Windows.Markup.XamlReader]::Load( $reader )

# Store Form Objects In PowerShell
$xaml.SelectNodes("//*[@Name]") | ForEach-Object { $syncHash."WPF$($_.Name)" = $syncHash.Form.FindName($_.Name) }

# create tray icon
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\mstsc.exe")

# Create notifyicon, and right-click -> Exit menu 
$notifyicon = New-Object System.Windows.Forms.NotifyIcon 
$notifyicon.Text = "DataGridApp" 
$notifyicon.Icon = $icon 
$notifyicon.Visible = $true 

$menuShowItem = New-Object System.Windows.Forms.MenuItem 
$menuShowItem.Text = "Restore" 

$menuExitItem = New-Object System.Windows.Forms.MenuItem 
$menuExitItem.Text = "Exit" 


$contextmenu = New-Object System.Windows.Forms.ContextMenu 
$notifyicon.ContextMenu = $contextmenu 
$notifyicon.contextMenu.MenuItems.AddRange($menuExitItem) 
$notifyicon.contextMenu.MenuItems.AddRange("-") 
$notifyicon.contextMenu.MenuItems.AddRange($menuShowItem) 
 
# Add a left click that makes the Window appear in the lower right part of the screen, above the notify icon. 
$notifyicon.add_Click( { 
        if ($_.Button -eq [Windows.Forms.MouseButtons]::Left) { 
            $syncHash.Form.Visibility = "Visible"
            $synchash.Form.Show()
            $synchash.Form.WindowState = 'Normal'
            $syncHash.Form.Activate()

        } 
    }) 
       
# When Exit is clicked, close everything and kill the PowerShell process 
$menuExitItem.add_Click( { 
        $notifyicon.Visible = $false
        $syncHash.Form.Close() 
        Stop-Process $pid 
    })

$menuShowItem.add_Click( {
        $syncHash.Form.Visibility = "Visible"
        $synchash.Form.Show()
        $synchash.Form.WindowState = 'Normal'
        $syncHash.Form.Activate()
    })    

function Write-FormHost {
    param( [string]$Text )

    $syncHash.Form.Dispatcher.Invoke(
        [action] { $syncHash.WPFStatusTextBlock.Text = $Text }, "Render"
    )
}

function Write-FormHostError {
    param( [string]$Text )

    $syncHash.Form.Dispatcher.Invoke([action] { 
            $syncHash.WPFStatusTextBlock.Text = $Text 
            $syncHash.WPFStatusTextBlock.Foreground = 'Red'
            $syncHash.WPFProgressBar.Foreground = 'Red'
        }, "Render"
    )
}

function Get-Settings {
    Write-StatusProgress "settings loaded extra long message for testing field lenght" 
    if ($env:SDD_REMOTEAPP -eq $true) {
        $syncHash.WPFMRACheckBox.IsChecked = $true
    }
    else {
        $syncHash.WPFMRACheckBox.IsChecked = $false   
    }
}

$syncHash.WPFMRACheckBox.Add_Click( { 
       
        $saverunspace = [runspacefactory]::CreateRunspace()
        $saverunspace.ApartmentState = "STA"
        $saverunspace.ThreadOptions = "ReuseThread"
        $saverunspace.Open()
        $saverunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
        
        $syncHash.mode = $syncHash.WPFMRACheckBox.IsChecked
        $syncHash.f = $syncHash.globalFunctions

        $code = {
            Invoke-Expression $syncHash.f
                    
            [System.Environment]::SetEnvironmentVariable('SDD_REMOTEAPP', $syncHash.mode , [System.EnvironmentVariableTarget]::User)

            Write-StatusProgress "setings saved"
        }

        $PSInstance = [powershell]::Create().AddScript($code)
        $PSinstance.Runspace = $saverunspace
        $job = $PSinstance.BeginInvoke()
    });

$syncHash.WPFStartButton.Add_Click( { 
        
        $syncHash.WPFStartButton.IsEnabled = $False

        $btnrunspace = [runspacefactory]::CreateRunspace()
        $btnrunspace.ApartmentState = "STA"
        $btnrunspace.ThreadOptions = "ReuseThread"
        $btnrunspace.Open()
        $btnrunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)

        $syncHash.remoteAppMode = $syncHash.WPFMRACheckBox.IsChecked
        $syncHash.f = $syncHash.globalFunctions
              
        $code = {
            Invoke-Expression $syncHash.f
            function StartButtonEnable {
                $syncHash.Form.Dispatcher.Invoke(
                    [action] { $syncHash.WPFStartButton.IsEnabled = $true })
            }
      
            function LoadProgress ($msg = "loading") {
                For ($i = 0; $i -le 10; $i++) {
                    Write-StatusProgress "$($msg) ." $i
                    Start-Sleep -Milliseconds 100
                    Write-StatusProgress "$($msg) .."
                    Start-Sleep -Milliseconds 100
                    Write-StatusProgress "$($msg) ..."
                    Start-Sleep -Milliseconds 100
                }
            }

            function LoadGrid {

                $syncHash.Form.Dispatcher.Invoke([action] { 
                                
                        $syncHash.WPFDatagrid.AddChild([pscustomobject]@{Name = 'vm-name1'; IP = '10.2.1.1'; State = 'OK'; Expiration = '14 days' })
                        $syncHash.WPFDatagrid.AddChild([pscustomobject]@{Name = 'vm-name1'; IP = '10.2.1.1'; State = 'OK'; Expiration = '14 days' })

                    }, "Render"
                )
            }

            function FetchData {

                if (-not $syncHash.dataFetching) {
                            
                    $syncHash.dataFetching = $true
                    $syncHash.dataLoadError = $null
                            
                    $datarunspace = [runspacefactory]::CreateRunspace()
                    $datarunspace.ApartmentState = "STA"
                    $datarunspace.ThreadOptions = "ReuseThread"
                    $datarunspace.Open()
                    $datarunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
                            
                    $syncHash.f = $syncHash.globalFunctions

                    $code = {

                        Invoke-Expression $syncHash.f
                        "running fetch `n" | Out-File -FilePath out.log -Append -Force
                        Start-Sleep 5
                        $syncHash.dataFetching = $null                               
                        $syncHash.dataLoadError = $false
                    }
    
                    $PSInstance = [powershell]::Create().AddScript($code)
                    $PSinstance.Runspace = $datarunspace
                    $dataJob = $PSinstance.BeginInvoke()
    
                }
                else {
                    return $dataJob.isCompleted
                }

            }

            #Do {
            #    LoadProgress "fetching data"  
            #} while (FetchData) 
                    
            FetchData

            Do {
                LoadProgress "fetching data"
            } while ([string]::IsNullOrEmpty($syncHash.dataLoadError))

            if ($syncHash.dataLoadError) { Write-Error "failed to load data" } else { Write-StatusProgress "data loaded" }

            LoadGrid
            StartButtonEnable

        }
        
        $PSInstance = [powershell]::Create().AddScript($code)
        $PSinstance.Runspace = $btnrunspace
        $job = $PSinstance.BeginInvoke()

        #                $Runspace.Close()
        #$Runspace.Dispose()

    });

#Get-Settings
#Write-FormHostError "failed to load settings"

#        # Finalize and close gui runspace upon exit
#        $syncHash.Form.ShowDialog() | Out-Null
#        $syncHash.Error = $Error
#        $Runspace.Close()
#        $Runspace.Dispose()
#    });

# Load runspace with gui
#$psCmd.Runspace = $newRunspace
#$data = $psCmd.BeginInvoke()

# add Exit
$syncHash.Form.Add_Closing( { 
        [System.Windows.Forms.Application]::Exit()
        Stop-Process $pid 
    })

# hide to tray if minimized
$syncHash.Form.Add_Deactivated( { 
        if ($synchash.Form.WindowState -like 'Minimized') {
            $synchash.Form.Hide()
        }
    }) 

# Make PowerShell Disappear 
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);' 
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru 
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0) 

# Force garbage collection just to start slightly lower RAM usage. 
[System.GC]::Collect() 

$syncHash.Form.Visibility = 'Visible'
$syncHash.Form.Activate()

# Create an application context for it to all run within. 
# This helps with responsiveness, especially when clicking Exit. 
$appContext = New-Object System.Windows.Forms.ApplicationContext 
[void][System.Windows.Forms.Application]::Run($appContext)
