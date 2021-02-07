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
